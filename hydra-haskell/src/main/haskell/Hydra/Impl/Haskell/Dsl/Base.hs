module Hydra.Impl.Haskell.Dsl.Base (
  module Hydra.Impl.Haskell.Dsl.Base,
  module Hydra.Impl.Haskell.Dsl.Functions,
  module Hydra.Impl.Haskell.Dsl.Literals
) where

import Hydra.Core
import Hydra.Impl.Haskell.Dsl.Functions
import Hydra.Impl.Haskell.Dsl.Literals
import Hydra.Impl.Haskell.Dsl.Phantoms
import qualified Data.Map as M
import qualified Data.Set as S


-- Note: type abstraction and type application terms are not currently supported

apply :: Program (a -> b) -> Program a -> Program b
apply (Program fun) (Program arg) = program $ ExpressionApplication $ Application fun arg

field :: FieldName -> Program a -> Fld b
field fname prog = Fld (Field fname $ strip prog)

letProg :: Var a -> Program a -> Program b -> Program b
letProg (Var k) (Program v) (Program env) = program $ ExpressionLet $ Let k v env

list :: [Program a] -> Program [a]
list els = program $ ExpressionList $ strip <$> els

mapProg :: [(Program k, Program v)] -> Program (M.Map k v)
mapProg pairs = program $ ExpressionMap $ M.fromList $ stripPair <$> pairs
  where
    stripPair (kp, vp) = (strip kp, strip vp)

nominal :: Name -> (Program a) -> Program b
nominal name (Program term) = program $ ExpressionNominal $ NominalTerm name term

optional :: Maybe (Program a) -> Program (Maybe a)
optional m = program $ ExpressionOptional $ strip <$> m

-- Note: Haskell cannot check that the provided fields agree with a particular record type
record :: [Fld a] -> Program a
record fields = program $ ExpressionRecord $ stripField <$> fields

ref :: Name -> Program (Ref a)
ref name = program $ ExpressionElement name

set :: [Program a] -> Program (S.Set a)
set els = program $ ExpressionSet $ S.fromList $ strip <$> els

-- Note: Haskell cannot check that the provided field agrees with a particular union type
union :: Fld a -> Program a
union field = program $ ExpressionUnion $ stripField field

unit :: Program ()
unit = record []

var :: Var a -> Program a
var (Var v) = program $ ExpressionVariable v
