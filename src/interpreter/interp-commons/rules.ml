open Support

type rule =
  | ERuleIdent
  | ERuleMemRef
  | ERuleConst
  | ERuleSeq
  | ERuleLambdaAbs
  | ERuleLambdaAppEval
  | ERuleLambdaAppFuncRet
  | ERuleLambdaAppArgsEval
  | ERuleLambdaAppArgsRet
  | ERuleLambdaAppEnter
  | ERuleLambdaAppComplete
  | ERuleNativeLambdaApp
  | ERuleAssignIdEval
  | ERuleAssignStrEval
  | ERuleAssignRet
  | ERuleIfEval
  | ERuleIfRet
  | ERuleIfRetSym
  | ERuleWhileEval
  | ERuleWhileCondTrue
  | ERuleWhileCondFalse
  | ERuleWhileCondSym
  | ERuleWhileBodyDone
  | ERuleBreak
  | ERuleNext
  | ERuleReturn
  | ERuleDiscard
  | ERuleBlank

type passresult =
  (rule list * state) list *
  (rule list * state) list *
  (rule list * state) list

