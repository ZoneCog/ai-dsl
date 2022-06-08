module MinProof

import OrdProofs

import Data.Vect
import Data.Vect.Quantifiers

--------------------------------------------------------------------
-- Excercises to prove                                            --
--                                                                --
--   min(x, y) ≤ x and min(x, y) ≤ y                              --
--                                                                --
-- and other properties like commutativity.                       --
--                                                                --
-- According to                                                   --
--                                                                --
-- https://en.wikipedia.org/wiki/Maximal_and_minimal_elements     --
--                                                                --
-- The minimal element m of set S, is defined such that           --
--                                                                --
--   ∀s∈S, if s ≤ m then m ≤ s                                    --
--                                                                --
-- given as only assumption about ≤ that it is a preorder,        --
-- i.e. reflexive and transitive.                                 --
--                                                                --
-- Thus in our case, strictly following the definition, what we   --
-- want to ensure is that                                         --
--                                                                --
--   if x ≤ min(x, y) then min(x, y) ≤ x                          --
--   if y ≤ min(x, y) then min(x, y) ≤ y                          --
--                                                                --
-- If ≤ is antisymmetric, i.e. a partial order, then it becomes   --
--                                                                --
--   if x ≤ min(x, y) then min(x, y) = x                          --
--   if y ≤ min(x, y) then min(x, y) = y                          --
--                                                                --
-- Finally if ≤ is total, then it follows that                    --
--                                                                --
--   min(x, y) ≤ x and min(x, y) ≤ y                              --
--                                                                --
-- which is what we set out to prove at the beginning.            --
--------------------------------------------------------------------

---------------------------------------
-- Alternative implementation of min --
---------------------------------------

||| Redefinition of min for full control
my_min : Ord a => a -> a -> a
my_min x y = if x < y then x else y

-----------------
-- Test my_min --
-----------------

test_my_min_1 : my_min 3.1 4.1 = 3.1
test_my_min_1 = Refl

test_my_min_2 : my_min 12.0 (-3.0) = -3.0
test_my_min_2 = Refl

test_my_min_3 : Either (my_min 3.1 4.1 = 3.1) (my_min 3.1 4.1 = 4.1)
test_my_min_3 = Left Refl

-------------------------
-- Proofs about my_min --
-------------------------

||| Proof that my_min x y returns either x or y
my_min_eq_prf : Ord a => (x, y : a) -> Either (my_min x y = x) (my_min x y = y)
my_min_eq_prf x y with (x < y)
  _ | True = Left Refl
  _ | False = Right Refl

||| Proof that my_min is commutative
my_min_commutative_prf : Ord a => (x, y : a) -> my_min x y = my_min y x
my_min_commutative_prf x y with (x < y) proof eq1 | (y < x) proof eq2
  _ | True | False = Refl
  _ | False | True = Refl
  _ | False | False = sym (lt_connected_prf eq1 eq2)
  _ | True | True = absurd (trans (sym (lt_asymmetric_prf eq1)) eq2)
  -- Below are more decomposed proofs for the absurd and connected cases
  -- _ | True | True = absurd f_eq_t -- eq1 := x < y = True, eq2 := y < x = True
  --                   where f_eq_t : False = True
  --                         f_eq_t = trans f_eq_y_lt_x eq2
  --                         where f_eq_y_lt_x : False = y < x
  --                               f_eq_y_lt_x = sym y_lt_x_eq_f
  --                               where y_lt_x_eq_f : y < x = False
  --                                     y_lt_x_eq_f = lt_asymmetric_prf eq1
  -- _ | False | False = sym x_eq_y
  --                     where x_eq_y : x = y
  --                           x_eq_y = lt_connected_prf eq1 eq2

||| Proof that my_min x y is not greater than x and y
my_min_ngt_prf : Ord a => (x, y : a) -> (x < my_min x y = False, y < my_min x y = False)
my_min_ngt_prf x y with (x < y) proof eq
  _ | True = (lt_irreflexive_prf, lt_asymmetric_prf eq)
  _ | False = (eq, lt_irreflexive_prf)

||| Proof that my_min x y is equal to or lower than x and y
my_min_le_prf : Ord a => (x, y : a) -> (my_min x y <= x = True, my_min x y <= y = True)
my_min_le_prf x y with (x < y) proof eq
  _ | True = (le_reflexive_prf, le_strongly_connected_imp_prf x_nle_y)
             where x_nle_y : y <= x = False
                   x_nle_y = le_converse_complement_prf eq
  _ | False = (le_converse_complement_prf eq, le_reflexive_prf)

||| Minimum function decorated with the proof of its correctness.
||| This is to explore the pros and cons of having the specification
||| inside the type signature of the function.
my_min_with_prf : Ord a => (x, y : a) -> (m : a ** (m <= x = True, m <= y = True))
my_min_with_prf x y = (my_min x y ** my_min_le_prf x y)

-------------------------------------------------------
-- Assuming a total order, prove that                --
--                                                   --
--   If m∈S is a minimal element of S, then ∀s∈S m≤s --
-------------------------------------------------------

||| Return the minimal element of a vector of at least one element.
min_element : Ord a => Vect (S n) a -> a
min_element (x :: []) = x
min_element (x :: (y :: ys)) = my_min x (min_element (y :: ys))

||| Proof that min_element [x₁, ..., xₙ] is equal to or lower than x₁ to xₙ
min_element_le_prf : Ord a => (xs : Vect (S n) a) -> All (\x : a => (min_element xs) <= x = True) xs
min_element_le_prf (x :: []) = le_reflexive_prf :: []
min_element_le_prf (x :: (y :: ys)) = head_prf :: tail_prf
  where head_prf : (min_element (x :: (y :: ys))) <= x = True
        head_prf = fst (my_min_le_prf x (min_element (y :: ys)))
        tail_prf : All (\z : a => (min_element (x :: (y :: ys))) <= z = True) (y :: ys)
        tail_prf = mapProperty prf_f (min_element_le_prf (y :: ys))
        where prf_f : {0 w : a} -> min_element (y :: ys) <= w = True -> min_element (x :: (y :: ys)) <= w = True
              prf_f prf with (x < min_element (y :: ys)) proof eq
                _ | True = le_transitive_prf (le_reflexive_closure_lt_prf (Left eq)) prf
                _ | False = prf

||| Minimal element function decorated with the proof of its
||| correctness.  This is to explore the pros and cons of having the
||| specification inside the type signature of the function.
min_element_with_prf : Ord a => (xs : Vect (S n) a) -> (m : a ** All (\x : a => m <= x = True) xs)
min_element_with_prf xs = (min_element xs ** min_element_le_prf xs)
