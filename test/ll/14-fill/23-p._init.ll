%BasicSubtype = type {ptr}
%Type0 = type {ptr, i32, [1 x i32]}
%Type1 = type {ptr, i32, [1 x {ptr addrspace(1), i32}]}
@_Bi04root0 = constant {i32, i32, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, i64, ptr, [0 x i64]} {i32 0, i32 0, i64 0, ptr @_bal_list_generic_get_tagged, ptr @_bal_list_generic_set_tagged, ptr @_bal_list_generic_inexact_set_tagged, ptr @_bal_list_generic_get_int, ptr @_bal_list_generic_set_int, ptr @_bal_list_generic_inexact_set_int, ptr @_bal_list_generic_get_float, ptr @_bal_list_generic_set_float, ptr @_bal_list_generic_inexact_set_float, i64 ptrtoint(ptr @.member0 to i64), ptr null, [0 x i64] []}
@.subtype0 = internal constant %Type0 {ptr @_bal_precomputed_subtype_contains, i32 1, [1 x i32] [i32 1]}, align 8
@.member0 = internal constant {i32, i32, [1 x ptr]} {i32 0, i32 4096, [1 x ptr] [ptr bitcast(ptr @.subtype0 to ptr)]}
@_Bi04root1 = constant {i32, i32, i64, ptr, [1 x i64]} {i32 0, i32 1, i64 1, ptr null, [1 x i64] [i64 9]}
@_Bi04root2 = constant {i32, i32, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, i64, ptr, [4 x i64]} {i32 1, i32 4, i64 4, ptr @_bal_list_generic_get_tagged, ptr @_bal_list_generic_set_tagged, ptr @_bal_list_generic_inexact_set_tagged, ptr @_bal_list_generic_get_int, ptr @_bal_list_generic_set_int, ptr @_bal_list_generic_inexact_set_int, ptr @_bal_list_generic_get_float, ptr @_bal_list_generic_set_float, ptr @_bal_list_generic_inexact_set_float, i64 1, ptr null, [4 x i64] [i64 9, i64 ptrtoint(ptr @.member1 to i64), i64 17, i64 65]}
@.subtype1 = internal constant %Type1 {ptr @_bal_record_subtype_contains, i32 1, [1 x {ptr addrspace(1), i32}] [{ptr addrspace(1), i32} {ptr addrspace(1) getelementptr(i8, ptr addrspace(1) null, i64 2738188573441261409), i32 4}]}, align 8
@.member1 = internal constant {i32, i32, [1 x ptr]} {i32 0, i32 8192, [1 x ptr] [ptr bitcast(ptr @.subtype1 to ptr)]}
declare ptr addrspace(1) @_bal_list_generic_get_tagged(ptr addrspace(1), i64)
declare i64 @_bal_list_generic_set_tagged(ptr addrspace(1), i64, ptr addrspace(1))
declare i64 @_bal_list_generic_inexact_set_tagged(ptr addrspace(1), i64, ptr addrspace(1))
declare i64 @_bal_list_generic_get_int(ptr addrspace(1), i64)
declare i64 @_bal_list_generic_set_int(ptr addrspace(1), i64, i64)
declare i64 @_bal_list_generic_inexact_set_int(ptr addrspace(1), i64, i64)
declare double @_bal_list_generic_get_float(ptr addrspace(1), i64)
declare i64 @_bal_list_generic_set_float(ptr addrspace(1), i64, double)
declare i64 @_bal_list_generic_inexact_set_float(ptr addrspace(1), i64, double)
declare i1 @_bal_precomputed_subtype_contains(ptr, ptr addrspace(1))
declare i1 @_bal_record_subtype_contains(ptr, ptr addrspace(1))
declare void @_B04rootmain()
define void @_bal_main() {
  call void @_B04rootmain()
  ret void
}