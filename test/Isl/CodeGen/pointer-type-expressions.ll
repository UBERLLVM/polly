; RUN: opt %loadPolly -polly-ast -analyze < %s | FileCheck %s
; RUN: opt %loadPolly -polly-codegen -S < %s | FileCheck %s -check-prefix=CODEGEN

; TODO: FIXME: IslExprBuilder is not capable of producing valid code
;              for arbitrary pointer expressions at the moment. Until
;              this is fixed we disallow pointer expressions completely.
; XFAIL: *

; void f(int a[], int N, float *P) {
;   int i;
;   for (i = 0; i < N; ++i)
;     if (P != 0)
;       a[i] = i;
; }

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128"

define void @f(i64* nocapture %a, i64 %N, float * %P) nounwind {
entry:
  br label %bb

bb:
  %i = phi i64 [ 0, %entry ], [ %i.inc, %bb.backedge ]
  %brcond = icmp ne float* %P, null
  br i1 %brcond, label %store, label %bb.backedge

store:
  %scevgep = getelementptr i64, i64* %a, i64 %i
  store i64 %i, i64* %scevgep
  br label %bb.backedge

bb.backedge:
  %i.inc = add nsw i64 %i, 1
  %exitcond = icmp eq i64 %i.inc, %N
  br i1 %exitcond, label %return, label %bb

return:
  ret void
}

; CHECK: if (P <= -1) {
; CHECK:   for (int c0 = 0; c0 < N; c0 += 1)
; CHECK:     Stmt_store(c0);
; CHECK: } else if (P >= 1)
; CHECK:   for (int c0 = 0; c0 < N; c0 += 1)
; CHECK:     Stmt_store(c0);
; CHECK: }

; CODEGEN:   %[[R0:[0-9]*]] = bitcast float* %P to i8*
; CODEGEN:   %[[R1:[0-9]*]] = bitcast float* %P to i8*
; CODEGEN-NEXT:   icmp ule i8* %[[R1]], inttoptr (i64 -1 to i8*)

