module Hydra.ArbitraryCore where

import Hydra.Core
import Hydra.Impl.Haskell.Dsl.Terms
import Hydra.Impl.Haskell.Extras

import qualified Control.Monad as CM
import qualified Data.List as L
import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.Maybe as Y
import qualified Test.QuickCheck as QC


instance QC.Arbitrary LiteralType
  where
    arbitrary = QC.oneof [
      pure LiteralTypeBinary,
      pure LiteralTypeBoolean,
      LiteralTypeFloat <$> QC.arbitrary,
      LiteralTypeInteger <$> QC.arbitrary,
      pure LiteralTypeString]

instance QC.Arbitrary Literal
  where
    arbitrary = QC.oneof [
      LiteralBinary <$> QC.arbitrary,
      LiteralBoolean <$> QC.arbitrary,
      LiteralFloat <$> QC.arbitrary,
      LiteralInteger <$> QC.arbitrary,
      LiteralString <$> QC.arbitrary]

instance QC.Arbitrary BooleanValue
  where
    arbitrary = QC.oneof $ pure <$> [ BooleanValueFalse, BooleanValueTrue ]

instance QC.Arbitrary FloatType
  where
    arbitrary = QC.oneof $ pure <$> [
      FloatTypeBigfloat,
      FloatTypeFloat32,
      FloatTypeFloat64]

instance QC.Arbitrary FloatValue
  where
    arbitrary = QC.oneof [
      FloatValueBigfloat <$> QC.arbitrary,
      FloatValueFloat32 <$> QC.arbitrary,
      FloatValueFloat64 <$> QC.arbitrary]

instance QC.Arbitrary IntegerType
  where
    arbitrary = QC.oneof $ pure <$> [
      IntegerTypeBigint,
      IntegerTypeInt8,
      IntegerTypeInt16,
      IntegerTypeInt32,
      IntegerTypeInt64,
      IntegerTypeUint8,
      IntegerTypeUint16,
      IntegerTypeUint32,
      IntegerTypeUint64]

instance QC.Arbitrary IntegerValue
  where
    arbitrary = QC.oneof [
      IntegerValueBigint <$> QC.arbitrary,
      IntegerValueInt8 <$> QC.arbitrary,
      IntegerValueInt16 <$> QC.arbitrary,
      IntegerValueInt32 <$> QC.arbitrary,
      IntegerValueInt64 <$> QC.arbitrary,
      IntegerValueUint8 <$> QC.arbitrary,
      IntegerValueUint16 <$> QC.arbitrary,
      IntegerValueUint32 <$> QC.arbitrary,
      IntegerValueUint64 <$> QC.arbitrary]

instance (Default a, Eq a, Ord a, Read a, Show a) => QC.Arbitrary (Term a) where
  arbitrary = (\(TypedTerm _ term) -> term) <$> QC.sized arbitraryTypedTerm
  
instance QC.Arbitrary Type where
  arbitrary = QC.sized arbitraryType
  shrink typ = case typ of
    TypeLiteral at -> TypeLiteral <$> case at of
      LiteralTypeInteger _ -> [LiteralTypeBoolean]
      LiteralTypeFloat _ -> [LiteralTypeBoolean]
      _ -> []
    _ -> [] -- TODO

instance (Default a, Eq a, Ord a, Read a, Show a) => QC.Arbitrary (TypedTerm a) where
  arbitrary = QC.sized arbitraryTypedTerm
  shrink (TypedTerm typ term) = L.concat ((\(t, m) -> TypedTerm t <$> m term) <$> shrinkers typ)

arbitraryLiteral :: LiteralType -> QC.Gen Literal
arbitraryLiteral at = case at of
  LiteralTypeBinary -> LiteralBinary <$> QC.arbitrary
  LiteralTypeBoolean -> LiteralBoolean <$> QC.arbitrary
  LiteralTypeFloat ft -> LiteralFloat <$> arbitraryFloatValue ft
  LiteralTypeInteger it -> LiteralInteger <$> arbitraryIntegerValue it
  LiteralTypeString -> LiteralString <$> QC.arbitrary

arbitraryField :: (Default a, Eq a, Ord a, Read a, Show a) => FieldType -> Int -> QC.Gen (Field a)
arbitraryField (FieldType fn ft) n = Field fn <$> arbitraryTerm ft n

arbitraryFieldType :: Int -> QC.Gen FieldType
arbitraryFieldType n = FieldType <$> QC.arbitrary <*> arbitraryType n

arbitraryFloatValue :: FloatType -> QC.Gen FloatValue
arbitraryFloatValue ft = case ft of
  FloatTypeBigfloat -> FloatValueBigfloat <$> QC.arbitrary
  FloatTypeFloat32 -> FloatValueFloat32 <$> QC.arbitrary
  FloatTypeFloat64 -> FloatValueFloat64 <$> QC.arbitrary

-- Note: primitive functions and data terms are not currently generated, as they require a context.
arbitraryFunction :: (Default a, Eq a, Ord a, Read a, Show a) => FunctionType -> Int -> QC.Gen (Function a)
arbitraryFunction (FunctionType dom cod) n = QC.oneof $ defaults ++ whenEqual ++ domainSpecific
  where
    n' = decr n
    defaults = [
      -- Note: this simple lambda is a bit of a cheat. We just have to make sure we can generate at least one term
      --       for any supported function type.
      FunctionLambda <$> (Lambda "x" <$> arbitraryTerm cod n')]
     -- Note: two random types will rarely be equal, but it will happen occasionally with simple types
    whenEqual = [FunctionCompareTo <$> arbitraryTerm dom n' | dom == cod]
    domainSpecific = case dom of
      TypeUnion sfields -> [FunctionCases <$> CM.mapM arbitraryCase sfields]
        where
          arbitraryCase (FieldType fn dom') = do
            term <- arbitraryFunction (FunctionType dom' cod) n2
            return $ Field fn $ defaultTerm $ ExpressionFunction term
          n2 = div n' $ L.length sfields
        -- Note: projections now require nominally-typed records
--      TypeRecord sfields -> [FunctionProjection <$> (fieldTypeName <$> QC.elements sfields) | not (L.null sfields)]
--      TypeOptional ot -> [FunctionOptionalCases <$> (
--        OptionalCases <$> arbitraryTerm cod n'
--          <*> (defaultTerm . ExpressionFunction
--          <$> arbitraryFunction (FunctionType ot cod) n'))]
      _ -> []

arbitraryIntegerValue :: IntegerType -> QC.Gen IntegerValue
arbitraryIntegerValue it = case it of
  IntegerTypeBigint -> IntegerValueBigint <$> QC.arbitrary
  IntegerTypeInt8 -> IntegerValueInt8 <$> QC.arbitrary
  IntegerTypeInt16 -> IntegerValueInt16 <$> QC.arbitrary
  IntegerTypeInt32 -> IntegerValueInt32 <$> QC.arbitrary
  IntegerTypeInt64 -> IntegerValueInt64 <$> QC.arbitrary
  IntegerTypeUint8 -> IntegerValueUint8 <$> QC.arbitrary
  IntegerTypeUint16 -> IntegerValueUint16 <$> QC.arbitrary
  IntegerTypeUint32 -> IntegerValueUint32 <$> QC.arbitrary
  IntegerTypeUint64 -> IntegerValueUint64 <$> QC.arbitrary

arbitraryList :: Bool -> (Int -> QC.Gen a) -> Int -> QC.Gen [a]
arbitraryList nonempty g n = do
  l <- QC.choose (0, div n 2)
  if nonempty && l == 0
    then do
      x <- g (decr n)
      return [x]
    else QC.vectorOf l (g (div n l))

arbitraryOptional :: (Int -> QC.Gen a) -> Int -> QC.Gen (Maybe a)
arbitraryOptional gen n = do
  b <- QC.arbitrary
  if b || n == 0 then pure Nothing else Just <$> gen (decr n)

arbitraryPair :: (a -> a -> b) -> (Int -> QC.Gen a) -> Int -> QC.Gen b
arbitraryPair c g n = c <$> g n' <*> g n'
  where n' = div n 2

-- Note: variables and function applications are not (currently) generated
arbitraryTerm :: (Default a, Eq a, Ord a, Read a, Show a) => Type -> Int -> QC.Gen (Term a)
arbitraryTerm typ n = case typ of
    TypeLiteral at -> atomic <$> arbitraryLiteral at
    TypeFunction ft -> defaultTerm . ExpressionFunction <$> arbitraryFunction ft n'
    TypeList lt -> list <$> arbitraryList False (arbitraryTerm lt) n'
    TypeMap (MapType kt vt) -> defaultTerm . ExpressionMap <$> (M.fromList <$> arbitraryList False arbPair n')
      where
        arbPair n = do
            k <- arbitraryTerm kt n'
            v <- arbitraryTerm vt n'
            return (k, v)
          where
            n' = div n 2
    TypeOptional ot -> optional <$> arbitraryOptional (arbitraryTerm ot) n'
    TypeRecord sfields -> record <$> arbitraryFields sfields
    TypeSet st -> set <$> (S.fromList <$> arbitraryList False (arbitraryTerm st) n')
    TypeUnion sfields -> union <$> do
      f <- QC.elements sfields
      let fn = fieldTypeName f
      ft <- arbitraryTerm (fieldTypeType f) n'
      return $ Field fn ft
  where
    n' = decr n
    arbitraryFields sfields = if L.null sfields
        then pure []
        else CM.mapM (`arbitraryField` n2) sfields
      where
        n2 = div n' $ L.length sfields

-- Note: nominal types and element types are not currently generated, as instantiating them requires a context
arbitraryType :: Int -> QC.Gen Type
arbitraryType n = if n == 0 then pure unitType else QC.oneof [
    TypeLiteral <$> QC.arbitrary,
    TypeFunction <$> arbitraryPair FunctionType arbitraryType n',
    TypeList <$> arbitraryType n',
    TypeMap <$> arbitraryPair MapType arbitraryType n',
    TypeOptional <$> arbitraryType n',
    TypeRecord <$> arbitraryList False arbitraryFieldType n', -- TODO: avoid duplicate field names
    TypeSet <$> arbitraryType n',
    TypeUnion <$> arbitraryList True arbitraryFieldType n'] -- TODO: avoid duplicate field names
  where n' = decr n

arbitraryTypedTerm :: (Default a, Eq a, Ord a, Read a, Show a) => Int -> QC.Gen (TypedTerm a)
arbitraryTypedTerm n = do
    typ <- arbitraryType n'
    term <- arbitraryTerm typ n'
    return $ TypedTerm typ term
  where
    n' = div n 2 -- TODO: a term is usually bigger than its type

decr :: Int -> Int
decr n = max 0 (n-1)

-- Note: shrinking currently discards any metadata
shrinkers :: (Default a, Eq a, Ord a, Read a, Show a) => Type -> [(Type, (Term a) -> [Term a])]
shrinkers typ = trivialShrinker ++ case typ of
    TypeLiteral at -> case at of
      LiteralTypeBinary -> [(binaryType, \(Term (ExpressionLiteral (LiteralBinary s)) _) -> binaryTerm <$> QC.shrink s)]
      LiteralTypeBoolean -> []
      LiteralTypeFloat ft -> []
      LiteralTypeInteger it -> []
      LiteralTypeString -> [(stringType, \(Term (ExpressionLiteral (LiteralString s)) _) -> stringValue <$> QC.shrink s)]
  --  TypeElement et ->
  --  TypeFunction ft ->
    TypeList lt -> dropElements : promoteType : shrinkType
      where
        dropElements = (TypeList lt, \(Term (ExpressionList els) _) -> list <$> dropAny els)
        promoteType = (lt, \(Term (ExpressionList els) _) -> els)
        shrinkType = (\(t, m) -> (TypeList t, \(Term (ExpressionList els) _) -> list <$> CM.mapM m els)) <$> shrinkers lt
    TypeMap mt@(MapType kt vt) -> shrinkKeys ++ shrinkValues ++ dropPairs
      where
        shrinkKeys = (\(t, m) -> (TypeMap (MapType t vt),
            \(Term (ExpressionMap mp) _) -> defaultTerm . ExpressionMap . M.fromList <$> (shrinkPair m <$> M.toList mp))) <$> shrinkers kt
          where
            shrinkPair m (km, vm) = (\km' -> (km', vm)) <$> m km
        shrinkValues = (\(t, m) -> (TypeMap (MapType kt t),
            \(Term (ExpressionMap mp) _) -> defaultTerm . ExpressionMap . M.fromList <$> (shrinkPair m <$> M.toList mp))) <$> shrinkers vt
          where
            shrinkPair m (km, vm) = (\vm' -> (km, vm')) <$> m vm
        dropPairs = [(TypeMap mt, \(Term (ExpressionMap m) _) -> defaultTerm . ExpressionMap . M.fromList <$> dropAny (M.toList m))]
  --  TypeNominal name ->
    TypeOptional ot -> toNothing : promoteType : shrinkType
      where
        toNothing = (TypeOptional ot, \(Term (ExpressionOptional m) _) -> optional <$> Y.maybe [] (const [Nothing]) m)
        promoteType = (ot, \(Term (ExpressionOptional m) _) -> Y.maybeToList m)
        shrinkType = (\(t, m) -> (TypeOptional t,
          \(Term (ExpressionOptional mb) _) -> Y.maybe [] (fmap (optional . Just) . m) mb)) <$> shrinkers ot
    TypeRecord sfields -> dropFields
        ++ shrinkFieldNames TypeRecord record (\(Term (ExpressionRecord dfields) _) -> dfields) sfields
        ++ promoteTypes ++ shrinkTypes
      where
        dropFields = dropField <$> indices
          where
            dropField i = (TypeRecord $ dropIth i sfields, \(Term (ExpressionRecord dfields) _)
              -> [record $ dropIth i dfields])
        promoteTypes = promoteField <$> indices
          where
            promoteField i = (fieldTypeType $ sfields !! i, \(Term (ExpressionRecord dfields) _)
              -> [fieldTerm $ dfields !! i])
        shrinkTypes = [] -- TODO
        indices = [0..(L.length sfields - 1)]
    TypeSet st -> dropElements : promoteType : shrinkType
      where
        dropElements = (TypeSet st, \(Term (ExpressionSet els) _) -> set . S.fromList <$> dropAny (S.toList els))
        promoteType = (st, \(Term (ExpressionSet els) _) -> S.toList els)
        shrinkType = (\(t, m) -> (TypeSet t, \(Term (ExpressionSet els) _) -> set . S.fromList <$> CM.mapM m (S.toList els))) <$> shrinkers st
    TypeUnion sfields -> dropFields
        ++ shrinkFieldNames TypeUnion (union . L.head) (\(Term (ExpressionUnion f) _) -> [f]) sfields
        ++ promoteTypes ++ shrinkTypes
      where
        dropFields = [] -- TODO
        promoteTypes = [] -- TODO
        shrinkTypes = [] -- TODO
    _ -> []
  where
    dropAny l = case l of
      [] -> []
      (h:r) -> [r] ++ ((h :) <$> dropAny r)
    dropIth i l = L.take i l ++ L.drop (i+1) l
    nodupes l = L.length (L.nub l) == L.length l
    trivialShrinker = [(unitType, const [unitTerm]) | typ /= unitType]
    shrinkFieldNames toType toTerm fromTerm sfields = forNames <$> altNames
      where
        forNames names = (toType $ withFieldTypeNames names sfields,
           \term -> [toTerm $ withFieldNames names $ fromTerm term])
        altNames = L.filter nodupes $ CM.mapM QC.shrink (fieldTypeName <$> sfields)
        withFieldTypeNames = L.zipWith (\n f -> FieldType n $ fieldTypeType f)
        withFieldNames = L.zipWith (\n f -> Field n $ fieldTerm f)

-- | A placeholder for a type name. Use in tests only, where a union term is needed but no type name is known.
untyped :: Name
untyped = show (dflt :: Meta)
