import wso2/nballerina.err;
import wso2/nballerina.bir;
import wso2/nballerina.types as t;
import wso2/nballerina.print.llvm;

type BuildError err:Semantic|err:Unimplemented;

type Alignment 1|8;

// Pointer tagging
// JBUG #31394 would be better to use shifts for these
                     //1234567812345678
const TAG_FACTOR   = 0x0100000000000000;
const POINTER_MASK = 0x00fffffffffffff8;

const int TAG_MASK     = 0x1f * TAG_FACTOR;
const int TAG_NIL      = 0;
const int TAG_BOOLEAN  = t:UT_BOOLEAN * TAG_FACTOR;
const int TAG_INT      = t:UT_INT * TAG_FACTOR;
const int TAG_FLOAT    = t:UT_FLOAT * TAG_FACTOR;
const int TAG_STRING   = t:UT_STRING * TAG_FACTOR;
const int TAG_ERROR   = t:UT_ERROR * TAG_FACTOR;

const int TAG_LIST_RW  = t:UT_LIST_RW * TAG_FACTOR;

const int TAG_BASIC_TYPE_MASK = 0xf * TAG_FACTOR;
const int TAG_BASIC_TYPE_LIST = t:UT_LIST_RO * TAG_FACTOR;
const int TAG_BASIC_TYPE_MAPPING = t:UT_MAPPING_RO * TAG_FACTOR;

const int FLAG_IMMEDIATE = 0x20 * TAG_FACTOR;
const int FLAG_EXACT = 0x4;

const TAG_SHIFT = 56;

const HEAP_ADDR_SPACE = 1;
const ALIGN_HEAP = 8;

const LLVM_INT = "i64";
const LLVM_DOUBLE = "double";
const LLVM_BOOLEAN = "i1";
const LLVM_VOID = "void";

final llvm:PointerType LLVM_TAGGED_PTR = heapPointerType("i8");
final llvm:PointerType LLVM_NIL_TYPE = LLVM_TAGGED_PTR;
final llvm:PointerType LLVM_TAGGED_PTR_WITHOUT_ADDR_SPACE = llvm:pointerType("i8");

type ValueType llvm:IntegralType;

const PANIC_ARITHMETIC_OVERFLOW = 1;
const PANIC_DIVIDE_BY_ZERO = 2;
const PANIC_TYPE_CAST = 3;
const PANIC_STACK_OVERFLOW = 4;
const PANIC_INDEX_OUT_OF_BOUNDS = 5;
const PANIC_LIST_TOO_LONG = 6;
const PANIC_STRING_TOO_LONG = 7;
const PANIC_LIST_STORE = 8;
const PANIC_MAPPING_STORE = 9;

type PanicIndex PANIC_ARITHMETIC_OVERFLOW|PANIC_DIVIDE_BY_ZERO|PANIC_TYPE_CAST|PANIC_STACK_OVERFLOW|PANIC_INDEX_OUT_OF_BOUNDS;

type RuntimeFunctionName "panic"|"panic_construct"|"error_construct"|"alloc"|
                         "list_set"|"list_has_type"|
                         "mapping_set"|"mapping_get"|"mapping_init_member"|"mapping_construct"|"mapping_has_type"|
                         "int_to_tagged"|"tagged_to_int"|"float_to_tagged"|
                         "string_eq"|"string_cmp"|"string_concat"|"eq"|"exact_eq"|"float_eq"|"float_exact_eq"|"tagged_to_float"|"float_to_int"|
                         "int_compare"|"float_compare"|"string_compare"|"boolean_compare"|
                         "array_int_compare"|"array_float_compare"|"array_string_compare"|"array_boolean_compare";

type RuntimeFunction readonly & record {|
    RuntimeFunctionName name;
    llvm:FunctionType ty;
    llvm:EnumAttribute[] attrs;
|};

final RuntimeFunction panicFunction = {
    name: "panic",
    ty: {
        returnType: "void",
        paramTypes: [LLVM_TAGGED_PTR]
    },
    attrs: ["noreturn", "cold"]
};

final RuntimeFunction panicConstructFunction = {
    name: "panic_construct",
    ty: {
        returnType: LLVM_TAGGED_PTR,
        paramTypes: ["i64"]
    },
    attrs: ["cold"]
};

final RuntimeFunction errorConstructFunction = {
    name: "error_construct",
    ty: {
        returnType: LLVM_TAGGED_PTR,
        paramTypes: [LLVM_TAGGED_PTR, "i64"]
    },
    attrs: []
};

final RuntimeFunction allocFunction = {
    name: "alloc",
    ty: {
        returnType: LLVM_TAGGED_PTR,
        paramTypes: ["i64"]
    },
    attrs: []
};

final RuntimeFunction listHasTypeFunction = {
    name: "list_has_type",
    ty: {
        returnType: "i1",
        paramTypes: [LLVM_TAGGED_PTR, "i64"]
    },
    attrs: ["readonly"]
};

final RuntimeFunction mappingHasTypeFunction = {
    name: "mapping_has_type",
    ty: {
        returnType: "i1",
        paramTypes: [LLVM_TAGGED_PTR, "i64"]
    },
    attrs: ["readonly"]
};

final RuntimeFunction intToTaggedFunction = {
    name: "int_to_tagged",
    ty: {
        returnType: LLVM_TAGGED_PTR,
        paramTypes: ["i64"]
    },
    attrs: [] // NB not readonly because it allocates storage
};

final RuntimeFunction floatToTaggedFunction = {
    name: "float_to_tagged",
    ty: {
        returnType: LLVM_TAGGED_PTR,
        paramTypes: ["double"]
    },
    attrs: [] // NB not readonly because it allocates storage
};

final RuntimeFunction floatToIntFunction = {
    name: "float_to_int",
    ty: {
        returnType: llvm:structType(["i64", "i1"]),
        paramTypes: ["double"]
    },
    attrs: ["nounwind", "readnone", "speculatable", "willreturn"]
};

final RuntimeFunction taggedToIntFunction = {
    name: "tagged_to_int",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction eqFunction = {
    name: "eq",
    ty: {
        returnType: "i1",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: [["return", "zeroext"], "readonly"]
};

final RuntimeFunction exactEqFunction = {
    name: "exact_eq",
    ty: {
        returnType: "i1",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: [["return", "zeroext"], "readonly"]
};

final RuntimeFunction taggedToFloatFunction = {
    name: "tagged_to_float",
    ty: {
        returnType: "double",
        paramTypes: [LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction floatEqFunction = {
    name: "float_eq",
    ty: {
        returnType: "i1",
        paramTypes:  ["double", "double"]
    },
    attrs: [["return", "zeroext"], "readonly"]
};

final RuntimeFunction floatExactEqFunction = {
    name: "float_exact_eq",
    ty: {
        returnType: "i1",
        paramTypes:  ["double", "double"]
    },
    attrs: [["return", "zeroext"], "readonly"]
};

final RuntimeFunction stringEqFunction = {
    name: "string_eq",
    ty: {
        returnType: "i1",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: [["return", "zeroext"], "readonly"]
};


final RuntimeFunction stringCmpFunction = {
    name: "string_cmp",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction intCompareFunction = {
    name: "int_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction floatCompareFunction = {
    name: "float_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction stringCompareFunction = {
    name: "string_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction booleanCompareFunction = {
    name: "boolean_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction arrayIntCompareFunction = {
    name: "array_int_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction arrayFloatCompareFunction = {
    name: "array_float_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction arrayStringCompareFunction = {
    name: "array_string_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};

final RuntimeFunction arrayBooleanCompareFunction = {
    name: "array_boolean_compare",
    ty: {
        returnType: "i64",
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: ["readonly"]
};
final RuntimeFunction stringConcatFunction = {
    name: "string_concat",
    ty: {
        returnType: LLVM_TAGGED_PTR,
        paramTypes: [LLVM_TAGGED_PTR, LLVM_TAGGED_PTR]
    },
    attrs: []
};

final bir:ModuleId runtimeModule = {
    org: "ballerinai",
    names: ["runtime"]
};

function buildFunctionBody(llvm:Builder builder, Scaffold scaffold, bir:FunctionCode code) returns BuildError? {
    foreach var b in code.blocks {
        check buildBasicBlock(builder, scaffold, b);
    }
}

function buildBasicBlock(llvm:Builder builder, Scaffold scaffold, bir:BasicBlock block) returns BuildError? {
    scaffold.setBasicBlock(block);
    builder.positionAtEnd(scaffold.basicBlock(block.label));
    foreach var insn in block.insns {
        if insn is bir:IntArithmeticBinaryInsn {
            buildArithmeticBinary(builder, scaffold, insn);
        }
        else if insn is bir:IntNoPanicArithmeticBinaryInsn {
            buildNoPanicArithmeticBinary(builder, scaffold, insn);
        }
        else if insn is bir:IntBitwiseBinaryInsn {
            buildBitwiseBinary(builder, scaffold, insn);
        }
        else if insn is bir:CompareInsn {
            check buildCompare(builder, scaffold, insn);
        }
        else if insn is bir:EqualityInsn {
            check buildEquality(builder, scaffold, insn);
        }
        else if insn is bir:BooleanNotInsn {
            buildBooleanNot(builder, scaffold, insn);
        }
        else if insn is bir:RetInsn {
            check buildRet(builder, scaffold, insn);
        }
        else if insn is bir:AssignInsn {
            check buildAssign(builder, scaffold, insn);
        }
        else if insn is bir:TypeCastInsn {
            check buildTypeCast(builder, scaffold, insn);
        }
        else if insn is bir:ConvertToIntInsn {
            check buildConvertToInt(builder, scaffold, insn);
        }
        else if insn is bir:ConvertToFloatInsn {
            check buildConvertToFloat(builder, scaffold, insn);
        }
        else if insn is bir:TypeTestInsn {
            check buildTypeTest(builder, scaffold, insn);
        }
        else if insn is bir:CondNarrowInsn {
            check buildCondNarrow(builder, scaffold, insn);
        }
        else if insn is bir:CallInsn {
            check buildCall(builder, scaffold, insn);
        }
        else if insn is bir:ListConstructInsn {
            check buildListConstruct(builder, scaffold, insn);
        }
        else if insn is bir:ListGetInsn {
            check buildListGet(builder, scaffold, insn);
        }
        else if insn is bir:ListSetInsn {
            check buildListSet(builder, scaffold, insn);
        }
        else if insn is bir:BranchInsn {
            check buildBranch(builder, scaffold, insn);
        }
        else if insn is bir:MappingConstructInsn {
            check buildMappingConstruct(builder, scaffold, insn);
        }
        else if insn is bir:MappingGetInsn {
            check buildMappingGet(builder, scaffold, insn);
        }
        else if insn is bir:MappingSetInsn {
            check buildMappingSet(builder, scaffold, insn);
        }
        else if insn is bir:StringConcatInsn {
            check buildStringConcat(builder, scaffold, insn);
        }
        else if insn is bir:CondBranchInsn {
            check buildCondBranch(builder, scaffold, insn);
        }
        else if insn is bir:AbnormalRetInsn {
            buildAbnormalRet(builder, scaffold, insn);
        }
        else if insn is bir:PanicInsn {
            buildPanic(builder, scaffold, insn);
        }
        else if insn is bir:ErrorConstructInsn {
            check buildErrorConstruct(builder, scaffold, insn);
        }
        else if insn is bir:FloatArithmeticBinaryInsn {
            buildFloatArithmeticBinary(builder, scaffold, insn);
        }
        else if insn is bir:FloatNegateInsn {
            buildFloatNegate(builder, scaffold, insn);
        }
        else {
            bir:CatchInsn unused = insn;
            // nothing to do
            // scaffold.panicAddress uses this to figure out where to store the panic info
        }
        scaffold.clearDebugLocation(builder);
    }
}

function buildBranch(llvm:Builder builder, Scaffold scaffold, bir:BranchInsn insn) returns BuildError? {
    builder.br(scaffold.basicBlock(insn.dest));
}

function buildCondBranch(llvm:Builder builder, Scaffold scaffold, bir:CondBranchInsn insn) returns BuildError? {
    builder.condBr(builder.load(scaffold.address(insn.operand)),
                   scaffold.basicBlock(insn.ifTrue),
                   scaffold.basicBlock(insn.ifFalse));
}

function buildRet(llvm:Builder builder, Scaffold scaffold, bir:RetInsn insn) returns BuildError? {
    RetRepr repr = scaffold.getRetRepr();
    builder.ret(repr is Repr ? check buildWideRepr(builder, scaffold, insn.operand, repr, scaffold.returnType) : ());
}

function buildAbnormalRet(llvm:Builder builder, Scaffold scaffold, bir:AbnormalRetInsn insn) {
    buildCallPanic(builder, scaffold, <llvm:PointerValue>builder.load(scaffold.address(insn.operand)));
}

function buildPanic(llvm:Builder builder, Scaffold scaffold, bir:PanicInsn insn) {
    builder.store(builder.load(scaffold.address(insn.operand)), scaffold.panicAddress());
    builder.br(scaffold.getOnPanic());
}

function buildCallPanic(llvm:Builder builder, Scaffold scaffold, llvm:PointerValue err) {
    _ = builder.call(buildRuntimeFunctionDecl(scaffold, panicFunction), [err]);
    builder.unreachable();
}

function buildAssign(llvm:Builder builder, Scaffold scaffold, bir:AssignInsn insn) returns BuildError? {
    builder.store(check buildWideRepr(builder, scaffold, insn.operand, scaffold.getRepr(insn.result), insn.result.semType),
                  scaffold.address(insn.result));
}

function buildCall(llvm:Builder builder, Scaffold scaffold, bir:CallInsn insn) returns BuildError? {
    scaffold.setDebugLocation(builder, insn.position);
    // Handler indirect calls later
    bir:FunctionRef funcRef = <bir:FunctionRef>insn.func;
    llvm:Value[] args = [];
    bir:FunctionSignature signature = funcRef.erasedSignature;
    t:SemType[] paramTypes = signature.paramTypes;
    foreach int i in 0 ..< insn.args.length() {
        args.push(check buildWideRepr(builder, scaffold, insn.args[i], semTypeRepr(paramTypes[i]), paramTypes[i]));
    }

    bir:Symbol funcSymbol = funcRef.symbol;
    llvm:Function func;
    if funcSymbol is bir:InternalSymbol {
        func = scaffold.getFunctionDefn(funcSymbol.identifier);
    }
    else {
        func = check buildFunctionDecl(scaffold, funcSymbol, signature);
    }  
    llvm:Value? retValue = builder.call(func, args);
    RetRepr retRepr = semTypeRetRepr(signature.returnType);
    check buildStoreRet(builder, scaffold, retRepr, retValue, insn.result);
}

function buildErrorConstruct(llvm:Builder builder, Scaffold scaffold, bir:ErrorConstructInsn insn) returns BuildError? {
    scaffold.setDebugLocation(builder, insn.position, "file");
    llvm:Value value = <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, errorConstructFunction),
                                                [
                                                    check buildString(builder, scaffold, insn.operand),
                                                    llvm:constInt(LLVM_INT, scaffold.lineNumber(insn.position))
                                                ]);
    builder.store(value, scaffold.address(insn.result));
}


function buildStringConcat(llvm:Builder builder, Scaffold scaffold, bir:StringConcatInsn insn) returns BuildError? {
    llvm:Value value = <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, stringConcatFunction),
                                                [
                                                    check buildString(builder, scaffold, insn.operands[0]),
                                                    check buildString(builder, scaffold, insn.operands[1])
                                                ]);
    builder.store(value, scaffold.address(insn.result));
}

function buildStoreRet(llvm:Builder builder, Scaffold scaffold, RetRepr retRepr, llvm:Value? retValue, bir:Register reg) returns BuildError? {
    if retRepr is Repr {
        builder.store(check buildConvertRepr(builder, scaffold, retRepr, <llvm:Value>retValue, scaffold.getRepr(reg)),
                      scaffold.address(reg));
    }
    else {
         builder.store(buildConstNil(), scaffold.address(reg));
    }
}

function buildFunctionDecl(Scaffold scaffold, bir:ExternalSymbol symbol, bir:FunctionSignature sig) returns llvm:FunctionDecl|BuildError {
    llvm:FunctionDecl? decl = scaffold.getImportedFunction(symbol);
    if !(decl is ()) {
        return decl;
    }
    else {
        // TODO: fix this: scaffold.location(0)
        llvm:FunctionType ty = check buildFunctionSignature(sig, scaffold.location(0));
        llvm:Module mod = scaffold.getModule();
        llvm:FunctionDecl d = mod.addFunctionDecl(mangleExternalSymbol(symbol), ty);
        scaffold.addImportedFunction(symbol, d);
        return d;
    }
}

function buildRuntimeFunctionDecl(Scaffold scaffold, RuntimeFunction rf) returns llvm:FunctionDecl {
    bir:ExternalSymbol symbol =  { module: runtimeModule, identifier: rf.name };
    llvm:FunctionDecl? decl = scaffold.getImportedFunction(symbol);
    if !(decl is ()) {
        return decl;
    }
    else {
        llvm:Module mod = scaffold.getModule();
        llvm:FunctionDecl f = mod.addFunctionDecl(mangleRuntimeSymbol(rf.name), rf.ty);
        foreach var attr in rf.attrs {
            f.addEnumAttribute(attr);
        }
        scaffold.addImportedFunction(symbol, f);
        return f;
    } 
}

function buildArithmeticBinary(llvm:Builder builder, Scaffold scaffold, bir:IntArithmeticBinaryInsn insn) {
    llvm:IntrinsicFunctionName? intrinsicName = buildBinaryIntIntrinsic(insn.op);
    llvm:Value lhs = buildInt(builder, scaffold, insn.operands[0]);
    llvm:Value rhs = buildInt(builder, scaffold, insn.operands[1]);
    llvm:Value result;
    llvm:BasicBlock? joinBlock = ();
    if intrinsicName != () {
        llvm:FunctionDecl intrinsicFunction = scaffold.getIntrinsicFunction(intrinsicName);
        // XXX better to distinguish builder.call and builder.callVoid
        llvm:Value resultWithOverflow = <llvm:Value>builder.call(intrinsicFunction, [lhs, rhs]);
        llvm:BasicBlock continueBlock = scaffold.addBasicBlock();
        llvm:BasicBlock overflowBlock = scaffold.addBasicBlock();
        builder.condBr(builder.extractValue(resultWithOverflow, 1), overflowBlock, continueBlock);
        builder.positionAtEnd(overflowBlock);
        builder.store(buildErrorForConstPanic(builder, scaffold, PANIC_ARITHMETIC_OVERFLOW, insn.position), scaffold.panicAddress());
        builder.br(scaffold.getOnPanic());
        builder.positionAtEnd(continueBlock);
        result = builder.extractValue(resultWithOverflow, 0);
    }
    else {
        llvm:BasicBlock zeroDivisorBlock = scaffold.addBasicBlock();
        llvm:BasicBlock continueBlock = scaffold.addBasicBlock();
        builder.condBr(builder.iCmp("eq", rhs, llvm:constInt(LLVM_INT, 0)), zeroDivisorBlock, continueBlock);
        builder.positionAtEnd(zeroDivisorBlock);
        builder.store(buildErrorForConstPanic(builder, scaffold, PANIC_DIVIDE_BY_ZERO, insn.position), scaffold.panicAddress());
        builder.br(scaffold.getOnPanic());
        builder.positionAtEnd(continueBlock);
        continueBlock = scaffold.addBasicBlock();
        llvm:BasicBlock overflowBlock = scaffold.addBasicBlock();
        builder.condBr(builder.iBitwise("and",
                                        builder.iCmp("eq", lhs, llvm:constInt(LLVM_INT, int:MIN_VALUE)),
                                        builder.iCmp("eq", rhs, llvm:constInt(LLVM_INT, -1))),
                       overflowBlock,
                       continueBlock);
        builder.positionAtEnd(overflowBlock);
        llvm:IntArithmeticSignedOp op;
        if insn.op == "/" {
            op = "sdiv";
            builder.store(buildErrorForConstPanic(builder, scaffold, PANIC_ARITHMETIC_OVERFLOW, insn.position), scaffold.panicAddress());
            builder.br(scaffold.getOnPanic());
        }
        else {
            builder.store(llvm:constInt(LLVM_INT, 0), scaffold.address(insn.result));
            llvm:BasicBlock b = scaffold.addBasicBlock();
            builder.br(b);
            joinBlock = b;
            op = "srem";
        }
        builder.positionAtEnd(continueBlock);
        result = builder.iArithmeticSigned(op, lhs, rhs);
    }
    buildStoreInt(builder, scaffold, result, insn.result);                                  
    if !(joinBlock is ()) {
        builder.br(joinBlock);
        builder.positionAtEnd(joinBlock);
    }                         
}

function buildNoPanicArithmeticBinary(llvm:Builder builder, Scaffold scaffold, bir:IntNoPanicArithmeticBinaryInsn insn) {
    llvm:Value lhs = buildInt(builder, scaffold, insn.operands[0]);
    llvm:Value rhs = buildInt(builder, scaffold, insn.operands[1]);
    llvm:IntArithmeticOp op = intArithmeticOps.get(insn.op);
    llvm:Value result = builder.iArithmeticNoWrap(op, lhs, rhs);
    buildStoreInt(builder, scaffold, result, insn.result);                                  
}

function buildFloatArithmeticBinary(llvm:Builder builder, Scaffold scaffold, bir:FloatArithmeticBinaryInsn insn) {
    llvm:Value lhs = buildFloat(builder, scaffold, insn.operands[0]);
    llvm:Value rhs = buildFloat(builder, scaffold, insn.operands[1]);
    llvm:FloatArithmeticOp op = floatArithmeticOps.get(insn.op);
    llvm:Value result = builder.fArithmetic(op, lhs, rhs);
    buildStoreFloat(builder, scaffold, result, insn.result);                                  
}

function buildFloatNegate(llvm:Builder builder, Scaffold scaffold, bir:FloatNegateInsn insn) {
    llvm:Value operand = buildFloat(builder, scaffold, insn.operand);
    llvm:Value result = builder.fNeg(operand);
    buildStoreFloat(builder, scaffold, result, insn.result);
}

final readonly & map<llvm:IntBitwiseOp> binaryBitwiseOp = {
    "&": "and",
    "^": "xor",
    "|": "or",
    "<<": "shl",
    ">>": "ashr",
    ">>>" : "lshr"
};

function buildBitwiseBinary(llvm:Builder builder, Scaffold scaffold, bir:IntBitwiseBinaryInsn insn) {
    llvm:Value lhs = buildInt(builder, scaffold, insn.operands[0]);
    llvm:Value rhs = buildInt(builder, scaffold, insn.operands[1]);
    if insn.op is bir:BitwiseShiftOp {
        rhs = builder.iBitwise("and", llvm:constInt(LLVM_INT, 0x3F), rhs);
    }
    llvm:IntBitwiseOp op = binaryBitwiseOp.get(insn.op);
    llvm:Value result = builder.iBitwise(op, lhs, rhs);
    buildStoreInt(builder, scaffold, result, insn.result);                                  
}

function buildCompare(llvm:Builder builder, Scaffold scaffold, bir:CompareInsn insn) returns BuildError? {
    var [lhsRepr, lhsValue] = check buildReprValue(builder, scaffold, insn.operands[0]);
    var [rhsRepr, rhsValue] = check buildReprValue(builder, scaffold, insn.operands[1]);
    bir:Register result = insn.result;

    match [lhsRepr.base, rhsRepr.base] {
        [BASE_REPR_TAGGED, BASE_REPR_INT] => {
            buildCompareTaggedInt(builder, scaffold, buildIntCompareOp(insn.op), lhsValue, rhsValue, result);
        }
        [BASE_REPR_INT, BASE_REPR_TAGGED] => {
            buildCompareTaggedInt(builder, scaffold, buildIntCompareOp(flippedOrderOps.get(insn.op)), rhsValue, lhsValue, result);
        }
        [BASE_REPR_TAGGED, BASE_REPR_FLOAT] => {
            buildCompareTaggedFloat(builder, scaffold, buildFloatCompareOp(insn.op), lhsValue, rhsValue, result);
        }
        [BASE_REPR_FLOAT, BASE_REPR_TAGGED] => {
            buildCompareTaggedFloat(builder, scaffold, buildFloatCompareOp(flippedOrderOps.get(insn.op)), rhsValue, lhsValue, result);
        }
        [BASE_REPR_TAGGED, BASE_REPR_BOOLEAN] => {
            buildCompareTaggedBoolean(builder, scaffold, buildBooleanCompareOp(insn.op), lhsValue, rhsValue, result);
        }
        [BASE_REPR_BOOLEAN, BASE_REPR_TAGGED] => {
            buildCompareTaggedBoolean(builder, scaffold, buildBooleanCompareOp(flippedOrderOps.get(insn.op)), rhsValue, lhsValue, result);
        }
        [BASE_REPR_TAGGED, BASE_REPR_TAGGED] => {
            if insn.orderType is t:UT_STRING {
                buildCompareString(builder, scaffold, buildIntCompareOp(insn.op), lhsValue, rhsValue, result);
            }
            else {
                buildCompareTagged(builder, scaffold, insn, lhsValue, rhsValue, result);
            }
        }
        [BASE_REPR_INT, BASE_REPR_INT] => {
            buildCompareInt(builder, scaffold, buildIntCompareOp(insn.op), lhsValue, rhsValue, result);
        }
        [BASE_REPR_BOOLEAN, BASE_REPR_BOOLEAN] => {
            buildCompareInt(builder, scaffold, buildBooleanCompareOp(insn.op), lhsValue, rhsValue, result);
        }
        [BASE_REPR_FLOAT, BASE_REPR_FLOAT] => {
            buildCompareFloat(builder, scaffold, buildFloatCompareOp(insn.op), lhsValue, rhsValue, result);
        }
    }
}

final readonly & map<bir:OrderOp> flippedOrderOps = {
    ">=": "<=",
    ">" : "<",
    "<=": ">=",
    "<" : ">"
};

type TaggedCompareResultTransform readonly & record {|
    bir:OrderOp op;
    llvm:IntPredicate predicate;
    int compareResult;
|};

const COMPARE_UN = -1;
const COMPARE_LT = 0;
const COMPARE_EQ = 1;
const COMPARE_GT = 2;

final readonly & table<TaggedCompareResultTransform> key(op) taggedCompareResultTransforms = table [
    { op: ">=", predicate: "sge", compareResult: COMPARE_EQ },
    { op: ">", predicate: "eq", compareResult: COMPARE_GT },
    { op: "<=", predicate: "ule", compareResult: COMPARE_EQ },
    { op: "<", predicate: "eq", compareResult: COMPARE_LT }
];

type TaggedCompareFunction readonly & record {|
    bir:UniformOrderType op;
    RuntimeFunction compareFunction;
    RuntimeFunction arrayCompareFunction;
|};

final readonly & table<TaggedCompareFunction> key(op) compareFunctions = table [
    { op: t:UT_INT, compareFunction: intCompareFunction, arrayCompareFunction: arrayIntCompareFunction },
    { op: t:UT_FLOAT, compareFunction: floatCompareFunction, arrayCompareFunction: arrayFloatCompareFunction },
    { op: t:UT_BOOLEAN, compareFunction: booleanCompareFunction, arrayCompareFunction: arrayBooleanCompareFunction },
    { op: t:UT_STRING, compareFunction: stringCompareFunction, arrayCompareFunction: arrayStringCompareFunction }
];

function buildCompareTagged(llvm:Builder builder, Scaffold scaffold, bir:CompareInsn insn, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    bir:OrderType orderTy = insn.orderType;
    llvm:Value? compareResult = ();
    if orderTy is bir:OptOrderType {
        compareResult = builder.call(buildRuntimeFunctionDecl(scaffold, compareFunctions.get(orderTy.opt).compareFunction), [lhs, rhs]);
    }
    else if orderTy is bir:ArrayOrderType {
        compareResult = builder.call(buildRuntimeFunctionDecl(scaffold, compareFunctions.get(orderTy[0].opt).arrayCompareFunction), [lhs, rhs]);
    }
    if compareResult is () {
        panic error("failed to find runtime compare function");
    }
    else {
        TaggedCompareResultTransform transform = taggedCompareResultTransforms.get(insn.op);
        buildStoreBoolean(builder, scaffold, builder.iCmp(transform.predicate, compareResult, llvm:constInt(LLVM_INT, transform.compareResult)), insn.result);
    }
}

function buildCompareTaggedBasic(llvm:Builder builder, Scaffold scaffold, llvm:Value lhs, llvm:Value rhs, bir:Register result)
    returns [llvm:BasicBlock, llvm:BasicBlock] {
    llvm:BasicBlock bbNil = scaffold.addBasicBlock();
    llvm:BasicBlock bbNotNil = scaffold.addBasicBlock();
    llvm:BasicBlock bbJoin = scaffold.addBasicBlock();
    llvm:Value isNil = builder.iCmp("eq", lhs, llvm:constNull(llvm:pointerType("i8", 1)));
    builder.condBr(isNil, bbNil, bbNotNil);
    builder.positionAtEnd(bbNil);
    buildStoreBoolean(builder, scaffold, llvm:constInt(LLVM_BOOLEAN, 0), result);
    builder.br(bbJoin);
    builder.positionAtEnd(bbNotNil);
    return [bbNotNil, bbJoin];
}

function buildCompareTaggedInt(llvm:Builder builder, Scaffold scaffold, llvm:IntPredicate op, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    var [bbNotNil, bbJoin] = buildCompareTaggedBasic(builder, scaffold, lhs, rhs, result);
    llvm:Value lhsUntagged = buildUntagInt(builder, scaffold, <llvm:PointerValue>lhs);
    buildCompareInt(builder, scaffold, op, lhsUntagged, rhs, result);
    builder.br(bbJoin);
    builder.positionAtEnd(bbJoin);
}

function buildCompareTaggedFloat(llvm:Builder builder, Scaffold scaffold, llvm:FloatPredicate op, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    var [bbNotNil, bbJoin] = buildCompareTaggedBasic(builder, scaffold, lhs, rhs, result);
    llvm:Value lhsUntagged = buildUntagFloat(builder, scaffold, <llvm:PointerValue>lhs);
    buildCompareFloat(builder, scaffold, op, lhsUntagged, rhs, result);
    builder.br(bbJoin);
    builder.positionAtEnd(bbJoin);
}

function buildCompareTaggedBoolean(llvm:Builder builder, Scaffold scaffold, llvm:IntPredicate op, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    var [bbNotNil, bbJoin] = buildCompareTaggedBasic(builder, scaffold, lhs, rhs, result);
    llvm:Value lhsUntagged = buildUntagBoolean(builder, <llvm:PointerValue>lhs);
    buildCompareInt(builder, scaffold, op, lhsUntagged, rhs, result);
    builder.br(bbJoin);
    builder.positionAtEnd(bbJoin);
}

function buildCompareInt(llvm:Builder builder, Scaffold scaffold, llvm:IntPredicate op, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    buildStoreBoolean(builder, scaffold, builder.iCmp(op, lhs, rhs), result);
}

function buildCompareFloat(llvm:Builder builder, Scaffold scaffold, llvm:FloatPredicate op, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    buildStoreBoolean(builder, scaffold, builder.fCmp(op, lhs, rhs), result);
}

function buildCompareString(llvm:Builder builder, Scaffold scaffold, llvm:IntPredicate op, llvm:Value lhs, llvm:Value rhs, bir:Register result) {
    buildStoreBoolean(builder, scaffold,
                      builder.iCmp(op, <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, stringCmpFunction), [lhs, rhs]),
                                   llvm:constInt(LLVM_INT, 0)),
                      result);
}

type CmpEqOp "ne"|"eq";

function buildEquality(llvm:Builder builder, Scaffold scaffold, bir:EqualityInsn insn) returns BuildError? {
    var [lhsRepr, lhsValue] = check buildReprValue(builder, scaffold, insn.operands[0]);
    var [rhsRepr, rhsValue] = check buildReprValue(builder, scaffold, insn.operands[1]);
    CmpEqOp op = insn.op[0] == "!" ?  "ne" : "eq"; 
    // JBUG cast
    boolean exact = (<string>insn.op).length() == 3; // either "===" or "!=="
    bir:Register result = insn.result;
    match [lhsRepr.base, rhsRepr.base] {
        [BASE_REPR_TAGGED, BASE_REPR_TAGGED] => {
            if reprIsImmediate(lhsRepr) || reprIsImmediate(rhsRepr) {
                return buildStoreBoolean(builder, scaffold, builder.iCmp(op, lhsValue, rhsValue), result);
            }
            else if reprIsString(lhsRepr) && reprIsString(rhsRepr) {
                if isAnyOperandSmallString(insn.operands) {
                    return buildStoreBoolean(builder, scaffold, builder.iCmp(op, lhsValue, rhsValue), result);
                }
                return buildEqualStringString(builder, scaffold, op, <llvm:PointerValue>lhsValue, <llvm:PointerValue>rhsValue, result);
            }
            else {
                return buildEqualTaggedTagged(builder, scaffold, exact, op, <llvm:PointerValue>lhsValue, <llvm:PointerValue>rhsValue, result);
            }
        }
        [BASE_REPR_TAGGED, BASE_REPR_BOOLEAN] => {
            return buildEqualTaggedBoolean(builder, scaffold, op, <llvm:PointerValue>lhsValue, rhsValue, result);
        }
        [BASE_REPR_BOOLEAN, BASE_REPR_TAGGED] => {
            return buildEqualTaggedBoolean(builder, scaffold, op, <llvm:PointerValue>rhsValue, lhsValue, result);
        }
        [BASE_REPR_TAGGED, BASE_REPR_INT] => {
            return buildEqualTaggedInt(builder, scaffold, op, <llvm:PointerValue>lhsValue, rhsValue, result);
        }
        [BASE_REPR_INT, BASE_REPR_TAGGED] => {
            return buildEqualTaggedInt(builder, scaffold, op, <llvm:PointerValue>rhsValue, lhsValue, result);
        }
        [BASE_REPR_BOOLEAN, BASE_REPR_BOOLEAN]
        | [BASE_REPR_INT, BASE_REPR_INT] => {
             // no tags involved, same representation, boolean/int
            return buildStoreBoolean(builder, scaffold, builder.iCmp(op, lhsValue, rhsValue), result);
        }
        [BASE_REPR_TAGGED, BASE_REPR_FLOAT] => {
            return buildEqualTaggedFloat(builder, scaffold, exact, op, <llvm:PointerValue>lhsValue, rhsValue, result);
        }
        [BASE_REPR_FLOAT, BASE_REPR_TAGGED] => {
            return buildEqualTaggedFloat(builder, scaffold, exact, op, <llvm:PointerValue>rhsValue, lhsValue, result);
        }
        [BASE_REPR_FLOAT, BASE_REPR_FLOAT] => {
            return buildEqualFloat(builder, scaffold, exact, op, lhsValue, rhsValue, result);
        }
    }
    return scaffold.unimplementedErr("equality with two different untagged representations");
}

function buildEqualTaggedFloat(llvm:Builder builder, Scaffold scaffold, boolean exact, CmpEqOp op, llvm:PointerValue tagged, llvm:Value untagged, bir:Register result) {
    llvm:BasicBlock floatTagBlock = scaffold.addBasicBlock();
    llvm:BasicBlock otherTagBlock = scaffold.addBasicBlock();
    llvm:BasicBlock joinBlock = scaffold.addBasicBlock();
    builder.condBr(buildHasTag(builder, tagged, TAG_FLOAT), floatTagBlock, otherTagBlock);
    builder.positionAtEnd(otherTagBlock);
    buildStoreBoolean(builder, scaffold,
                      // result is false if op is "eq", true if op is "ne"
                      buildConstBoolean(op == "ne"),
                      result);
    builder.br(joinBlock);
    builder.positionAtEnd(floatTagBlock);
    buildEqualFloat(builder, scaffold, exact, op, buildUntagFloat(builder, scaffold, tagged), untagged, result);
    builder.br(joinBlock);
    builder.positionAtEnd(joinBlock);
}

function buildEqualFloat(llvm:Builder builder, Scaffold scaffold, boolean exact, CmpEqOp op, llvm:Value lhsValue, llvm:Value rhsValue, bir:Register reg) {
    RuntimeFunction eqFunc = exact ? floatExactEqFunction : floatEqFunction;
    llvm:Value b = <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, eqFunc), [lhsValue, rhsValue]);
    if op == "ne" {
        b = builder.iBitwise("xor", b, llvm:constInt(LLVM_BOOLEAN, 1));
    }
    return buildStoreBoolean(builder, scaffold, b, reg);
}

function isAnyOperandSmallString(bir:Operand[] operands) returns boolean {
    foreach var operand in operands {
        if operand is string {
            byte[] bytes = operand.toBytes();
            int nBytes = operand.length();
            if isSmallString(operand.length(), bytes, nBytes) {
                return true;
            }
        }
    }
    return false;
}

function reprIsNil(Repr repr) returns boolean {
    return repr is TaggedRepr && repr.subtype == t:NIL;
}

function reprIsString(Repr repr) returns boolean {
    return repr is TaggedRepr && repr.subtype == t:STRING;
}

function reprIsImmediate(Repr repr) returns boolean {
    return !(repr is TaggedRepr) || (repr.subtype & ~(t:NIL|t:BOOLEAN)) == 0;
}

function buildEqualTaggedBoolean(llvm:Builder builder, Scaffold scaffold, CmpEqOp op, llvm:PointerValue tagged, llvm:Value untagged, bir:Register result)  {
    buildStoreBoolean(builder, scaffold,
                      builder.iCmp(op, tagged, buildTaggedBoolean(builder, untagged)),
                      result);
}

function buildEqualTaggedInt(llvm:Builder builder, Scaffold scaffold, CmpEqOp op, llvm:PointerValue tagged, llvm:Value untagged, bir:Register result) {
    llvm:BasicBlock intTagBlock = scaffold.addBasicBlock();
    llvm:BasicBlock otherTagBlock = scaffold.addBasicBlock();
    llvm:BasicBlock joinBlock = scaffold.addBasicBlock();
    builder.condBr(buildHasTag(builder, tagged, TAG_INT), intTagBlock, otherTagBlock);
    builder.positionAtEnd(otherTagBlock);
    buildStoreBoolean(builder, scaffold,
                      // result is false if op is "eq", true if op is "ne"
                      buildConstBoolean(op == "ne"),
                      result);
    builder.br(joinBlock);
    builder.positionAtEnd(intTagBlock);
    buildStoreBoolean(builder, scaffold, builder.iCmp(op, buildUntagInt(builder, scaffold, tagged), untagged), result);
    builder.br(joinBlock);
    builder.positionAtEnd(joinBlock);
}

function buildEqualTaggedTagged(llvm:Builder builder, Scaffold scaffold, boolean exact, CmpEqOp op, llvm:PointerValue tagged1, llvm:PointerValue tagged2, bir:Register result) {
    RuntimeFunction func = exact ? exactEqFunction : eqFunction;
    llvm:Value b = <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, func), [tagged1, tagged2]);
    if op == "ne" {
        b = builder.iBitwise("xor", b, llvm:constInt(LLVM_BOOLEAN, 1));
    }
    buildStoreBoolean(builder, scaffold, b, result);
}

function buildEqualStringString(llvm:Builder builder, Scaffold scaffold, CmpEqOp op, llvm:PointerValue tagged1, llvm:PointerValue tagged2, bir:Register result) {
    llvm:Value b = <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, stringEqFunction), [tagged1, tagged2]);
    if op == "ne" {
        b = builder.iBitwise("xor", b, llvm:constInt(LLVM_BOOLEAN, 1));
    }
    buildStoreBoolean(builder, scaffold, b, result);
}

function buildTypeTest(llvm:Builder builder, Scaffold scaffold, bir:TypeTestInsn insn) returns BuildError? {
    var [repr, val] = check buildReprValue(builder, scaffold, insn.operand);
    if repr.base != BASE_REPR_TAGGED {
         // in subset 5 should be const true/false
        return scaffold.unimplementedErr("test of untagged value");
    }
    t:SemType semType = insn.semType;
    llvm:PointerValue tagged = <llvm:PointerValue>val;
    llvm:Value hasType;
    if semType === t:BOOLEAN {
        hasType = buildHasTag(builder, tagged, TAG_BOOLEAN);
    }
    else if semType === t:INT {
        hasType = buildHasTag(builder, tagged, TAG_INT);
    }
    else if semType === t:FLOAT {
        hasType = buildHasTag(builder, tagged, TAG_FLOAT);
    }
    else if semType === t:STRING {
        hasType = buildHasTag(builder, tagged, TAG_STRING);
    }
    else if semType === t:ERROR {
        hasType = buildHasTag(builder, tagged, TAG_ERROR);
    }
    else if t:isSubtypeSimple(semType, t:LIST) {
        hasType = buildHasListType(builder, scaffold, tagged, insn.operand.semType, semType);
    }
    else if t:isSubtypeSimple(semType, t:MAPPING) {
        hasType = buildHasMappingType(builder, scaffold, tagged, insn.operand.semType, semType);
    }
    else if semType is t:UniformTypeBitSet {
        hasType = buildHasTagInSet(builder, tagged, semType);
    }
    else {
        return scaffold.unimplementedErr("unimplemented type test"); // should not happen in subset 6
    }
    if insn.negated {
        buildStoreBoolean(builder, scaffold, 
                    builder.iBitwise("xor", llvm:constInt(LLVM_BOOLEAN, 1), hasType), 
                    insn.result);
    }
    else {
        buildStoreBoolean(builder, scaffold, hasType, insn.result);
    }
}

function buildHasListType(llvm:Builder builder, Scaffold scaffold, llvm:PointerValue tagged, t:SemType sourceType, t:SemType targetType) returns llvm:Value {
    if t:intersect(sourceType, t:LIST) == targetType {
        return buildHasBasicTypeTag(builder, tagged, TAG_BASIC_TYPE_LIST);
    }
    else {
        t:UniformTypeBitSet bitSet = <t:UniformTypeBitSet>t:simpleArrayMemberType(scaffold.typeContext(), targetType);
        return <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, listHasTypeFunction),
                                        [tagged, llvm:constInt(LLVM_INT, bitSet)]);      
    }
}

function buildHasMappingType(llvm:Builder builder, Scaffold scaffold, llvm:PointerValue tagged, t:SemType sourceType, t:SemType targetType) returns llvm:Value {
    if t:intersect(sourceType, t:MAPPING) == targetType {
        return buildHasBasicTypeTag(builder, tagged, TAG_BASIC_TYPE_MAPPING);
    }
    else {
        t:UniformTypeBitSet bitSet = <t:UniformTypeBitSet>t:simpleMapMemberType(scaffold.typeContext(), targetType);
        return <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, mappingHasTypeFunction),
                                        [tagged, llvm:constInt(LLVM_INT, bitSet)]);      
    }
}

function buildTypeCast(llvm:Builder builder, Scaffold scaffold, bir:TypeCastInsn insn) returns BuildError? {
    var [repr, val] = check buildReprValue(builder, scaffold, insn.operand);
    if repr.base != BASE_REPR_TAGGED {
        return scaffold.unimplementedErr("cast from untagged value"); // should not happen in subset 2
    }
    llvm:PointerValue tagged = <llvm:PointerValue>val;
    llvm:BasicBlock continueBlock = scaffold.addBasicBlock();
    llvm:BasicBlock castFailBlock = scaffold.addBasicBlock();
    t:SemType semType = insn.semType;
    if semType === t:BOOLEAN {
        builder.condBr(buildHasTag(builder, tagged, TAG_BOOLEAN), continueBlock, castFailBlock);
        builder.positionAtEnd(continueBlock);
        buildStoreBoolean(builder, scaffold, buildUntagBoolean(builder, tagged), insn.result);
    }
    else if semType === t:INT {
        builder.condBr(buildHasTag(builder, tagged, TAG_INT), continueBlock, castFailBlock);
        builder.positionAtEnd(continueBlock);
        buildStoreInt(builder, scaffold, buildUntagInt(builder, scaffold, tagged), insn.result);
    }
    else if semType === t:FLOAT {
        builder.condBr(buildHasTag(builder, tagged, TAG_FLOAT), continueBlock, castFailBlock);
        builder.positionAtEnd(continueBlock);
        buildStoreFloat(builder, scaffold, buildUntagFloat(builder, scaffold, tagged), insn.result);
    }
    else {
        llvm:Value hasTag;
        if semType === t:STRING {
            hasTag = buildHasTag(builder, tagged, TAG_STRING);
        }
        else if semType === t:ERROR {
            hasTag = buildHasTag(builder, tagged, TAG_ERROR);
        }
        else if t:isSubtypeSimple(semType, t:LIST) {
            hasTag = buildHasListType(builder, scaffold, tagged, insn.operand.semType, semType);
        }
        else if t:isSubtypeSimple(semType, t:MAPPING) {
            hasTag = buildHasMappingType(builder, scaffold, tagged, insn.operand.semType, semType);
        }
        else if semType is t:UniformTypeBitSet {
            hasTag = buildHasTagInSet(builder, tagged, semType);
        }
        else {
            return scaffold.unimplementedErr("unimplemented type cast"); // should not happen in subset 6
        }
        builder.condBr(hasTag, continueBlock, castFailBlock);
        builder.positionAtEnd(continueBlock);
        builder.store(tagged, scaffold.address(insn.result));
    }
    builder.positionAtEnd(castFailBlock);
    builder.store(buildErrorForConstPanic(builder, scaffold, PANIC_TYPE_CAST, insn.position), scaffold.panicAddress());
    builder.br(scaffold.getOnPanic());
    builder.positionAtEnd(continueBlock);
}

function buildConvertToInt(llvm:Builder builder, Scaffold scaffold, bir:ConvertToIntInsn insn) returns BuildError? {
    var [repr, val] = check buildReprValue(builder, scaffold, insn.operand);
    if repr.base == BASE_REPR_FLOAT {
        buildConvertFloatToInt(builder, scaffold, val, insn);
        return;
    }
    else if repr.base != BASE_REPR_TAGGED {
        return scaffold.unimplementedErr("convert form decimal to int");
    }
    // convert to int form tagged pointer

    t:SemType semType = insn.operand.semType;
    llvm:PointerValue tagged = <llvm:PointerValue>val;
    llvm:BasicBlock joinBlock = scaffold.addBasicBlock();

    // semType must contain float or decimal. Since we don't have decimal yet in subset 6,
    // it must contain float. In the future, below section is only needed conditionally.
    llvm:Value hasType = buildHasTag(builder, tagged, TAG_FLOAT);
    llvm:BasicBlock hasFloatBlock = scaffold.addBasicBlock();
    llvm:BasicBlock noFloatBlock = scaffold.addBasicBlock();
    builder.condBr(hasType, hasFloatBlock, noFloatBlock);
    builder.positionAtEnd(hasFloatBlock);
    buildConvertFloatToInt(builder, scaffold, buildUntagFloat(builder, scaffold, tagged), insn);
    builder.br(joinBlock);

    builder.positionAtEnd(<llvm:BasicBlock>noFloatBlock);
    if !t:isSubtypeSimple(semType, t:FLOAT) {
        builder.store(tagged, scaffold.address(insn.result));
    }
    builder.br(joinBlock);
    builder.positionAtEnd(joinBlock);
}

function buildConvertFloatToInt(llvm:Builder builder, Scaffold scaffold, llvm:Value floatVal, bir:ConvertToIntInsn insn) {
    llvm:Value resultWithErr = <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, floatToIntFunction), [floatVal]);
    llvm:BasicBlock continueBlock = scaffold.addBasicBlock();
    llvm:BasicBlock errBlock = scaffold.addBasicBlock();
    builder.condBr(builder.extractValue(resultWithErr, 1), errBlock, continueBlock);
    builder.positionAtEnd(errBlock);
    builder.store(buildErrorForConstPanic(builder, scaffold, PANIC_TYPE_CAST, insn.position), scaffold.panicAddress());
    builder.br(scaffold.getOnPanic());
    builder.positionAtEnd(continueBlock);
    llvm:Value result = builder.extractValue(resultWithErr, 0);
    buildStoreInt(builder, scaffold, result, insn.result);
}

function buildConvertToFloat(llvm:Builder builder, Scaffold scaffold, bir:ConvertToFloatInsn insn) returns BuildError? {
    var [repr, val] = check buildReprValue(builder, scaffold, insn.operand);
    if repr.base == BASE_REPR_INT {
        buildConvertIntToFloat(builder, scaffold, val, insn);
        return;
    }
    else if repr.base != BASE_REPR_TAGGED {
        return scaffold.unimplementedErr("convert form decimal to float");
    }
    // convert to float form tagged pointer

    // number part of semType must be some *non-empty* combination of
    // (some or all of) int, float and decimal
    t:SemType semType = insn.operand.semType;
    llvm:PointerValue tagged = <llvm:PointerValue>val;
    llvm:BasicBlock joinBlock = scaffold.addBasicBlock();

    // semType must contain int or decimal. Since we don't have decimal yet in subset 6,
    // it must contain int. In the future, below section is only needed conditionally.
    llvm:Value hasType = buildHasTag(builder, tagged, TAG_INT);
    llvm:BasicBlock hasIntBlock = scaffold.addBasicBlock();
    llvm:BasicBlock noIntBlock = scaffold.addBasicBlock();
    builder.condBr(hasType, hasIntBlock, noIntBlock);
    builder.positionAtEnd(hasIntBlock);
    buildConvertIntToFloat(builder, scaffold, buildUntagInt(builder, scaffold, tagged), insn);
    builder.br(joinBlock);

    builder.positionAtEnd(<llvm:BasicBlock>noIntBlock);
    if !t:isSubtypeSimple(semType, t:INT) {
        builder.store(tagged, scaffold.address(insn.result));
    }
    builder.br(joinBlock);
    builder.positionAtEnd(joinBlock);
}

function buildConvertIntToFloat(llvm:Builder builder, Scaffold scaffold, llvm:Value intVal, bir:ConvertToFloatInsn insn) {
    buildStoreFloat(builder, scaffold, builder.sIToFP(intVal, LLVM_DOUBLE), insn.result);
}

function buildCondNarrow(llvm:Builder builder, Scaffold scaffold, bir:CondNarrowInsn insn) returns BuildError? {
    var [sourceRepr, value] = check buildReprValue(builder, scaffold, insn.operand);
    llvm:Value narrowed = check buildNarrowRepr(builder, scaffold, sourceRepr, value, scaffold.getRepr(insn.result));
    builder.store(narrowed, scaffold.address(insn.result));
}

function buildNarrowRepr(llvm:Builder builder, Scaffold scaffold, Repr sourceRepr, llvm:Value value, Repr targetRepr) returns llvm:Value|BuildError {
    BaseRepr sourceBaseRepr = sourceRepr.base;
    BaseRepr targetBaseRepr = targetRepr.base;
    llvm:Value narrowed;
    if sourceBaseRepr == targetBaseRepr {
        return value;
    }
    if sourceBaseRepr == BASE_REPR_TAGGED {
        return buildUntagged(builder, scaffold, <llvm:PointerValue>value, targetRepr);
    }
    return scaffold.unimplementedErr("unimplemented narrowing conversion required");
}

function buildErrorForConstPanic(llvm:Builder builder, Scaffold scaffold, PanicIndex panicIndex, bir:Position pos) returns llvm:PointerValue {
    // JBUG #31753 cast
    return buildErrorForPackedPanic(builder, scaffold, llvm:constInt(LLVM_INT, <int>panicIndex | (scaffold.lineNumber(pos) << 8)), pos);
}

function buildErrorForPanic(llvm:Builder builder, Scaffold scaffold, llvm:Value panicIndex, bir:Position pos) returns llvm:PointerValue {
    return buildErrorForPackedPanic(builder, scaffold, builder.iBitwise("or", panicIndex, llvm:constInt(LLVM_INT, scaffold.lineNumber(pos) << 8)), pos);
}

function buildErrorForPackedPanic(llvm:Builder builder, Scaffold scaffold, llvm:Value packedPanic, bir:Position pos) returns llvm:PointerValue {
    scaffold.setDebugLocation(builder, pos, "file");
    var err = <llvm:PointerValue>builder.call(buildRuntimeFunctionDecl(scaffold, panicConstructFunction), [packedPanic]);
    scaffold.clearDebugLocation(builder);
    return err;
}

function buildBooleanNot(llvm:Builder builder, Scaffold scaffold, bir:BooleanNotInsn insn) {
    buildStoreBoolean(builder, scaffold,
                      builder.iBitwise("xor", llvm:constInt(LLVM_BOOLEAN, 1), builder.load(scaffold.address(insn.operand))),
                      insn.result);
}

function buildStoreInt(llvm:Builder builder, Scaffold scaffold, llvm:Value value, bir:Register reg) {
    builder.store(scaffold.getRepr(reg).base == BASE_REPR_TAGGED ? buildTaggedInt(builder, scaffold, value) : value,
                  scaffold.address(reg));
}

function buildStoreFloat(llvm:Builder builder, Scaffold scaffold, llvm:Value value, bir:Register reg) {
    builder.store(scaffold.getRepr(reg).base == BASE_REPR_TAGGED ? buildTaggedFloat(builder, scaffold, value) : value,
                  scaffold.address(reg));
}

function buildStoreBoolean(llvm:Builder builder, Scaffold scaffold, llvm:Value value, bir:Register reg) {
    builder.store(scaffold.getRepr(reg).base == BASE_REPR_TAGGED ? buildTaggedBoolean(builder, value) : value,
                  scaffold.address(reg));
}

function buildStoreTagged(llvm:Builder builder, Scaffold scaffold, llvm:Value value, bir:Register reg) {
    return builder.store(buildUntagged(builder, scaffold, <llvm:PointerValue>value, scaffold.getRepr(reg)), scaffold.address(reg));
}

function buildUntagged(llvm:Builder builder, Scaffold scaffold, llvm:PointerValue value, Repr targetRepr) returns llvm:Value {
    match targetRepr.base {
        BASE_REPR_INT => {
            return buildUntagInt(builder, scaffold, value);
        }
        BASE_REPR_FLOAT => {
            return buildUntagFloat(builder, scaffold, value);
        }
        BASE_REPR_BOOLEAN => {
            return buildUntagBoolean(builder, value);
        }
        BASE_REPR_TAGGED => {
            return value;
        }
    }
    panic err:impossible("unreached in buildUntagged");
}

function buildWideRepr(llvm:Builder builder, Scaffold scaffold, bir:Operand operand, Repr targetRepr, t:SemType targetType) returns llvm:Value|BuildError {
    llvm:Value value = check buildRepr(builder, scaffold, operand, targetRepr);
    if targetRepr.base == BASE_REPR_TAGGED && operand is bir:Register {
        t:SemType listOrMappingRw = t:union(t:LIST_RW, t:MAPPING_RW);
        t:SemType targetStructType = t:intersect(targetType, listOrMappingRw);
        t:SemType sourceStructType =  t:intersect(operand.semType, listOrMappingRw);
        if !t:isNever(targetStructType) && !t:isNever(sourceStructType) {
            // Is the sourceStructType a proper subtype of the targetStructType?
            if sourceStructType != targetStructType && !t:isSubtype(scaffold.typeContext(), targetStructType, sourceStructType) {
                value = buildClearExact(builder, scaffold, value, targetRepr);
            }
        }
    }
    return value;
}

function buildClearExact(llvm:Builder builder, Scaffold scaffold, llvm:Value value, Repr targetRepr) returns llvm:Value {
    // SUBSET need to use targetRepr to handle unions including mappings and lists
    // JBUG <int> cast needed (otherwise result is or'd with 0xFF)
    return <llvm:Value>builder.call(scaffold.getIntrinsicFunction("ptrmask.p1i8.i64"), [value, llvm:constInt(LLVM_INT, ~<int>FLAG_EXACT)]);
}

function buildRepr(llvm:Builder builder, Scaffold scaffold, bir:Operand operand, Repr targetRepr) returns llvm:Value|BuildError {
    var [sourceRepr, value] = check buildReprValue(builder, scaffold, operand);
    return buildConvertRepr(builder, scaffold, sourceRepr, value, targetRepr);
}

function buildConvertRepr(llvm:Builder builder, Scaffold scaffold, Repr sourceRepr, llvm:Value value, Repr targetRepr) returns llvm:Value|BuildError {
    BaseRepr sourceBaseRepr = sourceRepr.base;
    BaseRepr targetBaseRepr = targetRepr.base;
    if sourceBaseRepr == targetBaseRepr {
        return value;
    }
    if targetBaseRepr == BASE_REPR_TAGGED {
        if sourceBaseRepr == BASE_REPR_INT {
            return buildTaggedInt(builder, scaffold, value);
        }
        else if sourceBaseRepr == BASE_REPR_FLOAT {
            return buildTaggedFloat(builder, scaffold, value);
        }
        else if sourceBaseRepr == BASE_REPR_BOOLEAN {
            return buildTaggedBoolean(builder, value);
        }
    }
    // this shouldn't ever happen I think
    return scaffold.unimplementedErr("unimplemented conversion required");
}

function buildTaggedBoolean(llvm:Builder builder, llvm:Value value) returns llvm:Value {
    return builder.getElementPtr(llvm:constNull(LLVM_TAGGED_PTR),
                                     [builder.iBitwise("or",
                                                       builder.zExt(value, LLVM_INT),
                                                       llvm:constInt(LLVM_INT, TAG_BOOLEAN))]);
}

function buildTaggedInt(llvm:Builder builder, Scaffold scaffold, llvm:Value value) returns llvm:PointerValue {
    return <llvm:PointerValue>builder.call(buildRuntimeFunctionDecl(scaffold, intToTaggedFunction), [value]);
}

function buildTaggedFloat(llvm:Builder builder, Scaffold scaffold, llvm:Value value) returns llvm:PointerValue {
    return <llvm:PointerValue>builder.call(buildRuntimeFunctionDecl(scaffold, floatToTaggedFunction), [value]);
}

function buildTaggedPtr(llvm:Builder builder, llvm:PointerValue mem, int tag) returns llvm:PointerValue {
    return builder.getElementPtr(mem, [llvm:constInt(LLVM_INT, tag)]);
}

function buildTypedAlloc(llvm:Builder builder, Scaffold scaffold, llvm:Type ty) returns llvm:PointerValue {
    return builder.bitCast(buildUntypedAlloc(builder, scaffold, ty), heapPointerType(ty));
}

function buildUntypedAlloc(llvm:Builder builder, Scaffold scaffold, llvm:Type ty) returns llvm:PointerValue {
    return <llvm:PointerValue>builder.call(buildRuntimeFunctionDecl(scaffold, allocFunction),
                                           [llvm:constInt(LLVM_INT, typeSize(ty))]);
}

// XXX this should go in llvm module, because it needs to know about alignment
function typeSize(llvm:Type ty) returns int {
    if ty is llvm:PointerType || ty == "i64" {
        return 8;
    }
    else if ty is llvm:StructType {
        int size = 0;
        foreach var elemTy in ty.elementTypes {
            size += typeSize(elemTy);
        }
        return size;
    }
    else if ty is llvm:ArrayType {
        if ty.elementCount == 0 {
            panic error("cannot take size of 0-length array");
        }
        return ty.elementCount * typeSize(ty.elementType);
    }
    panic error("size of unsized type");
}

function buildHasTag(llvm:Builder builder, llvm:PointerValue tagged, int tag) returns llvm:Value {
    return buildTestTag(builder, tagged, tag, TAG_MASK);    
}

function buildHasBasicTypeTag(llvm:Builder builder, llvm:PointerValue tagged, int basicTypeTag) returns llvm:Value {
    return buildTestTag(builder, tagged, basicTypeTag, TAG_BASIC_TYPE_MASK);    
}

function buildTestTag(llvm:Builder builder, llvm:PointerValue tagged, int tag, int mask) returns llvm:Value {
    return builder.iCmp("eq", builder.iBitwise("and", buildTaggedPtrToInt(builder, tagged),
                                                       llvm:constInt(LLVM_INT, mask)),
                              llvm:constInt(LLVM_INT, tag));

}

function buildHasTagInSet(llvm:Builder builder, llvm:PointerValue tagged, t:UniformTypeBitSet bitSet) returns llvm:Value {
    return builder.iCmp("ne",
                        builder.iBitwise("and",
                                         builder.iBitwise("shl",
                                                          llvm:constInt(LLVM_INT, 1),
                                                          builder.iBitwise("lshr",
                                                                           // need to mask out the 0x20 bit
                                                                           builder.iBitwise("and",
                                                                                            buildTaggedPtrToInt(builder, tagged),
                                                                                            llvm:constInt(LLVM_INT, TAG_MASK)),
                                                                           llvm:constInt(LLVM_INT, TAG_SHIFT))),
                                         llvm:constInt(LLVM_INT, bitSet)),
                        llvm:constInt(LLVM_INT, 0));
}

function buildUntagInt(llvm:Builder builder, Scaffold scaffold, llvm:PointerValue tagged) returns llvm:Value {
    return <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, taggedToIntFunction), [tagged]);
}

function buildUntagFloat(llvm:Builder builder, Scaffold scaffold, llvm:PointerValue tagged) returns llvm:Value {
    return <llvm:Value>builder.call(buildRuntimeFunctionDecl(scaffold, taggedToFloatFunction), [tagged]);
}

function buildUntagBoolean(llvm:Builder builder, llvm:PointerValue tagged) returns llvm:Value {
    return builder.trunc(buildTaggedPtrToInt(builder, tagged), LLVM_BOOLEAN);
}

function buildTaggedPtrToInt(llvm:Builder builder, llvm:PointerValue tagged) returns llvm:Value {
    return builder.ptrToInt(builder.addrSpaceCast(tagged, LLVM_TAGGED_PTR_WITHOUT_ADDR_SPACE), LLVM_INT);
}

function buildReprValue(llvm:Builder builder, Scaffold scaffold, bir:Operand operand) returns [Repr, llvm:Value]|BuildError {
    if operand is bir:Register {
        return buildLoad(builder, scaffold, operand);
    }
    else if operand is string {
        return [REPR_STRING, check buildConstString(builder, scaffold, operand)];
    }
    else {
        return buildSimpleConst(operand);
    }
}

function buildConstString(llvm:Builder builder, Scaffold scaffold, string str) returns llvm:ConstPointerValue|BuildError {   
    return check scaffold.getString(str);
}

function addStringDefn(llvm:Context context, llvm:Module mod, int defnIndex, string str) returns llvm:ConstPointerValue|BuildError {
    int nCodePoints = str.length();
    byte[] bytes = str.toBytes();
    int nBytes = bytes.length();

    llvm:Type ty;
    llvm:ConstValue val;
    StringVariant variant;
    if isSmallString(nCodePoints, bytes, nBytes) {
        int encoded = 0;
        foreach int i in 0 ..< 7 {
            // JBUG cast needed #31867
            encoded |= <int>(i < nBytes ? bytes[i] : 0xFF) << i*8;
        }
        encoded |= FLAG_IMMEDIATE|TAG_STRING;
        return context.constGetElementPtr(llvm:constNull(LLVM_TAGGED_PTR), [llvm:constInt(LLVM_INT, encoded)]);
    }
    // if nBytes == nCodePoints && nBytes <= 0xFF {
    //     // We want the total size including the header to be a multiple of 8
    //     int nBytesPadded = padBytes(bytes, 1);
    //     val = context.constStruct([llvm:constInt("i8", nBytes), context.constString(bytes)]);
    //     ty = llvm:structType(["i8", llvm:arrayType("i8", nBytesPadded)]);
    //     variant = STRING_VARIANT_SMALL;
    // }
    else if nBytes <= 0xFFFF {
        int nBytesPadded = padBytes(bytes, 4);
        val = context.constStruct([llvm:constInt("i16", nBytes), llvm:constInt("i16", nCodePoints), context.constString(bytes)]);
        ty = llvm:structType(["i16", "i16", llvm:arrayType("i8", nBytesPadded)]);
        variant = STRING_VARIANT_MEDIUM;
    }
    else {
        int nBytesPadded = padBytes(bytes, 16);
        val = context.constStruct([llvm:constInt("i64", nBytes), llvm:constInt("i64", nCodePoints), context.constString(bytes)]);
        ty = llvm:structType(["i64", "i64", llvm:arrayType("i8", nBytesPadded)]);
        variant = STRING_VARIANT_LARGE;
    }
    llvm:ConstPointerValue ptr = mod.addGlobal(ty,
                                               stringDefnSymbol(defnIndex),
                                               initializer = val,
                                               align = 8,
                                               isConstant = true,
                                               unnamedAddr = true,
                                               linkage = "internal");
    return context.constGetElementPtr(context.constAddrSpaceCast(context.constBitCast(ptr, LLVM_TAGGED_PTR_WITHOUT_ADDR_SPACE), LLVM_TAGGED_PTR),
                                      [llvm:constInt(LLVM_INT, TAG_STRING | <int>variant)]);
}

function isSmallString(int nCodePoints, byte[] bytes, int nBytes) returns boolean {
    return nCodePoints == 1 || (nBytes == nCodePoints && nBytes <= 7);
}

// Returns the new, padded length
function padBytes(byte[] bytes, int headerSize) returns int {
    int nBytes = bytes.length();
    int nBytesPadded = (((nBytes + headerSize + 7) >> 3) << 3) - headerSize;
    foreach int i in 0 ..< nBytesPadded - nBytes {
        bytes.push(0);
    }
    return nBytesPadded;
}

function buildLoad(llvm:Builder builder, Scaffold scaffold, bir:Register reg) returns [Repr, llvm:Value] {
    return [scaffold.getRepr(reg), builder.load(scaffold.address(reg))];
}

function buildSimpleConst(bir:SimpleConstOperand operand) returns [Repr, llvm:Value] {
    if operand is int {
        return [REPR_INT, llvm:constInt(LLVM_INT, operand)];
    }
    else if operand is float {
        return [REPR_FLOAT, llvm:constFloat(LLVM_DOUBLE, operand)];
    }
    else if operand is () {
        return [REPR_NIL, buildConstNil()];
    }
    else {
        // operand is boolean
        return [REPR_BOOLEAN, llvm:constInt(LLVM_BOOLEAN, operand ? 1 : 0)];
    }
}

function buildString(llvm:Builder builder, Scaffold scaffold, bir:StringOperand operand) returns llvm:Value|BuildError {
    if operand is string {
        return buildConstString(builder, scaffold, operand);
    }
    else {
        return builder.load(scaffold.address(operand));
    }
}

// Build a value as REPR_INT
function buildInt(llvm:Builder builder, Scaffold scaffold, bir:IntOperand operand) returns llvm:Value {
    if operand is int {
        return llvm:constInt(LLVM_INT, operand);
    }
    else {
        return builder.load(scaffold.address(operand));
    }
}

// Build a value as REPR_FLOAT
function buildFloat(llvm:Builder builder, Scaffold scaffold, bir:FloatOperand operand) returns llvm:Value {
    if operand is float {
        return llvm:constFloat(LLVM_DOUBLE, operand);
    }
    else {
        return builder.load(scaffold.address(operand));
    }
}

// Build a value as REPR_BOOLEAN
function buildBoolean(llvm:Builder builder, Scaffold scaffold, bir:BooleanOperand operand) returns llvm:Value {
    if operand is boolean {
        return llvm:constInt(LLVM_BOOLEAN, operand ? 1 : 0);
    }
    else {
        return builder.load(scaffold.address(operand));
    }
}

final readonly & map<llvm:IntrinsicFunctionName> binaryIntIntrinsics = {
    "+": "sadd.with.overflow.i64",
    "-": "ssub.with.overflow.i64",
    "*": "smul.with.overflow.i64"
};

final readonly & map<llvm:IntArithmeticOp> intArithmeticOps = {
    "+": "add",
    "-": "sub",
    "*": "mul"
};

final readonly & map<llvm:FloatArithmeticOp> floatArithmeticOps = {
    "+": "fadd",
    "-": "fsub",
    "*": "fmul",
    "/": "fdiv",
    "%": "frem"
};

// final readonly & map<llvm:BinaryIntOp> binaryIntOps = {
//     "+": "add",
//     "-": "sub",
//     "*": "mul",
//     "/": "sdiv",
//     "%": "srem"
// };

// function buildBinaryIntOp(bir:ArithmeticBinaryOp op) returns llvm:BinaryIntOp {
//     return <llvm:BinaryIntOp>binaryIntOps[op];
// }

function buildBinaryIntIntrinsic(bir:ArithmeticBinaryOp op) returns llvm:IntrinsicFunctionName? {
    return binaryIntIntrinsics[op];
}

final readonly & map<llvm:IntPredicate> signedIntPredicateOps = {
    "<": "slt",
    "<=": "sle",
    ">": "sgt",
    ">=": "sge"
};

final readonly & map<llvm:IntPredicate> unsignedIntPredicateOps = {
    "<": "ult",
    "<=": "ule",
    ">": "ugt",
    ">=": "uge"
};

final readonly & map<llvm:FloatPredicate> floatPredicateOps = {
    "<": "olt",
    "<=": "ole",
    ">": "ogt",
    ">=": "oge"
};

function buildIntCompareOp(bir:OrderOp op) returns llvm:IntPredicate {
    return <llvm:IntPredicate>signedIntPredicateOps[op];
}

function buildFloatCompareOp(bir:OrderOp op) returns llvm:FloatPredicate {
    return <llvm:FloatPredicate>floatPredicateOps[op];
}

function buildBooleanCompareOp(bir:OrderOp op) returns llvm:IntPredicate {
    return <llvm:IntPredicate>unsignedIntPredicateOps[op];
}

function buildFunctionSignature(bir:FunctionSignature signature, err:Location loc) returns llvm:FunctionType|BuildError {
    llvm:Type[] paramTypes = from var ty in signature.paramTypes select (semTypeRepr(ty)).llvm;
    RetRepr repr = semTypeRetRepr(signature.returnType);
    llvm:FunctionType ty = {
        returnType: repr.llvm,
        paramTypes: paramTypes.cloneReadOnly()
    };
    return ty;
}

function buildConstNil() returns llvm:Value {
    return llvm:constNull(LLVM_NIL_TYPE);
}

function buildConstBoolean(boolean b) returns llvm:Value {
    return llvm:constInt(LLVM_BOOLEAN, b ? 1 : 0);
}


function heapPointerType(llvm:Type ty) returns llvm:PointerType {
    return llvm:pointerType(ty, HEAP_ADDR_SPACE);
}