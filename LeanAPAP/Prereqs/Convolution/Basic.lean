import Project.Mathlib.Algebra.BigOperators.Basic
import Project.Mathlib.Data.Finset.Basic
import Project.Mathlib.Data.Fintype.Basic
import Project.Mathlib.Data.Real.Nnreal
import Project.Prereqs.Indicator

#align_import prereqs.convolution.basic

/-!
# Convolution

This file defines several versions of the discrete convolution of functions.

## Main declarations

* `function.conv`: Discrete convolution of two functions
* `dconv`: Discrete difference convolution of two functions
* `iter_conv`: Iterated convolution of a function

## Notation

* `f ∗ g`: Convolution
* `f ○ g`: Difference convolution
* `f ∗^ n`: Iterated convolution

## Notes

Some lemmas could technically be generalised to a non-commutative semiring domain. Doesn't seem very
useful given that the codomain in applications is either `ℝ`, `ℝ≥0` or `ℂ`.

Similarly we could drop the commutativity assumption on the domain, but this is unneeded at this
point in time.

## TODO

Multiplicativise? Probably ugly and not very useful.
-/


open Finset Fintype Function

open scoped BigOperators ComplexConjugate Expectations NNReal Pointwise

variable {α β γ : Type _} [Fintype α] [DecidableEq α] [AddCommGroup α]

/-!
### Convolution of functions

In this section, we define the convolution `f ∗ g` and difference convolution `f ○ g` of functions
`f g : α → β`, and show how they interact.
-/


section CommSemiring

variable [CommSemiring β] [StarRing β] {f g : α → β}

-- PLEASE REPORT THIS TO MATHPORT DEVS, THIS SHOULD NOT HAPPEN.
-- failed to format: unknown constant 'BigOperators.Mathlib.Algebra.BigOperators.Basic.«term∑_with_,_»'
/-- Convolution -/ @[ nolint unused_arguments ]
  def
    Function.conv
    ( f g : α → β ) : α → β
    := fun a => ∑ x : α × α with x . 1 + x . 2 = a , f x . 1 * g x . 2

-- PLEASE REPORT THIS TO MATHPORT DEVS, THIS SHOULD NOT HAPPEN.
-- failed to format: unknown constant 'BigOperators.Mathlib.Algebra.BigOperators.Basic.«term∑_with_,_»'
/-- Difference convolution -/
  def
    dconv
    ( f g : α → β ) : α → β
    := fun a => ∑ x : α × α with x . 1 - x . 2 = a , f x . 1 * conj g x . 2

/-- The trivial character. -/
def trivChar : α → β := fun a => if a = 0 then 1 else 0

infixl:70 " ∗ " => Function.conv

infixl:70 " ○ " => dconv

-- PLEASE REPORT THIS TO MATHPORT DEVS, THIS SHOULD NOT HAPPEN.
-- failed to format: unknown constant 'BigOperators.Mathlib.Algebra.BigOperators.Basic.«term∑_with_,_»'
theorem
  conv_apply
  ( f g : α → β ) ( a : α ) : f ∗ g a = ∑ x : α × α with x . 1 + x . 2 = a , f x . 1 * g x . 2
  := rfl

-- PLEASE REPORT THIS TO MATHPORT DEVS, THIS SHOULD NOT HAPPEN.
-- failed to format: unknown constant 'BigOperators.Mathlib.Algebra.BigOperators.Basic.«term∑_with_,_»'
theorem
  dconv_apply
  ( f g : α → β ) ( a : α ) : f ○ g a = ∑ x : α × α with x . 1 - x . 2 = a , f x . 1 * conj g x . 2
  := rfl

@[simp]
theorem trivChar_apply (a : α) : (trivChar a : β) = if a = 0 then 1 else 0 :=
  rfl

@[simp]
theorem conv_conjneg (f g : α → β) : f ∗ conjneg g = f ○ g :=
  funext fun a =>
    sum_bij (fun x _ => (x.1, -x.2)) (fun x hx => by simpa using hx) (fun x _ => rfl)
      (fun x y _ _ h => by simpa [Prod.ext_iff] using h) fun x hx =>
      ⟨(x.1, -x.2), by simpa [sub_eq_add_neg] using hx, by simp⟩

@[simp]
theorem dconv_conjneg (f g : α → β) : f ○ conjneg g = f ∗ g := by
  rw [← conv_conjneg, conjneg_conjneg]

theorem conv_comm (f g : α → β) : f ∗ g = g ∗ f :=
  funext fun a =>
    sum_nbij' Prod.swap (fun x hx => by simpa [add_comm] using hx) (fun x _ => mul_comm _ _)
      Prod.swap (fun x hx => by simpa [add_comm] using hx) (fun x _ => x.swap_swap) fun x _ =>
      x.swap_swap

@[simp]
theorem conj_conv (f g : α → β) : conj (f ∗ g) = conj f ∗ conj g :=
  funext fun a => by simp only [Pi.conj_apply, conv_apply, map_sum, map_mul]

@[simp]
theorem conjneg_conv (f g : α → β) : conjneg (f ∗ g) = conjneg f ∗ conjneg g :=
  by
  funext a
  simp only [conv_apply, conjneg_apply, map_sum, map_mul]
  convert equiv.sum_comp_finset (Equiv.neg (α × α)) _ rfl using 2
  rw [← Equiv.coe_toEmbedding, ← map_eq_image (Equiv.neg (α × α)).symm.toEmbedding, map_filter]
  simp [Function.comp, ← neg_eq_iff_eq_neg, add_comm]

@[simp]
theorem conjneg_dconv (f g : α → β) : conjneg (f ○ g) = g ○ f := by
  simp_rw [← conv_conjneg, conjneg_conv, conjneg_conjneg, conv_comm]

theorem conv_assoc (f g h : α → β) : f ∗ g ∗ h = f ∗ (g ∗ h) :=
  by
  ext a
  simp only [sum_mul, mul_sum, conv_apply, sum_sigma']
  refine'
          sum_bij' (fun x hx => ⟨(x.2.1, x.2.2 + x.1.2), (x.2.2, x.1.2)⟩) _ _
            (fun x hx => ⟨(x.1.1 + x.2.1, x.2.2), (x.1.1, x.2.1)⟩) _ _ _ <;>
        simp only [mem_sigma, mem_filter, mem_univ, true_and_iff, Sigma.forall, Prod.forall,
          and_imp, heq_iff_eq] <;>
      rintro b c de rfl rfl <;>
    simp only [add_assoc, mul_assoc, Prod.mk.eta, eq_self_iff_true, and_self_iff]

theorem conv_right_comm (f g h : α → β) : f ∗ g ∗ h = f ∗ h ∗ g := by
  rw [conv_assoc, conv_assoc, conv_comm g]

theorem conv_left_comm (f g h : α → β) : f ∗ (g ∗ h) = g ∗ (f ∗ h) := by
  rw [← conv_assoc, ← conv_assoc, conv_comm g]

theorem conv_conv_conv_comm (f g h i : α → β) : f ∗ g ∗ (h ∗ i) = f ∗ h ∗ (g ∗ i) := by
  rw [conv_assoc, conv_assoc, conv_left_comm g]

theorem conv_dconv_conv_comm (f g h i : α → β) : f ∗ g ○ (h ∗ i) = f ○ h ∗ (g ○ i) := by
  simp_rw [← conv_conjneg, conjneg_conv, conv_conv_conv_comm]

theorem dconv_conv_dconv_comm (f g h i : α → β) : f ○ g ∗ (h ○ i) = f ∗ h ○ (g ∗ i) := by
  simp_rw [← conv_conjneg, conjneg_conv, conv_conv_conv_comm]

theorem dconv_dconv_dconv_comm (f g h i : α → β) : f ○ g ○ (h ○ i) = f ○ h ○ (g ○ i) := by
  simp_rw [← conv_conjneg, conjneg_conv, conv_conv_conv_comm]

@[simp]
theorem conv_zero (f : α → β) : f ∗ 0 = 0 := by ext <;> simp [conv_apply]

@[simp]
theorem zero_conv (f : α → β) : 0 ∗ f = 0 := by ext <;> simp [conv_apply]

@[simp]
theorem dconv_zero (f : α → β) : f ○ 0 = 0 := by simp [← conv_conjneg]

@[simp]
theorem zero_dconv (f : α → β) : 0 ○ f = 0 := by simp [← conv_conjneg]

theorem conv_add (f g h : α → β) : f ∗ (g + h) = f ∗ g + f ∗ h := by
  ext <;> simp only [conv_apply, mul_add, sum_add_distrib, Pi.add_apply]

theorem add_conv (f g h : α → β) : (f + g) ∗ h = f ∗ h + g ∗ h := by
  ext <;> simp only [conv_apply, add_mul, sum_add_distrib, Pi.add_apply]

theorem dconv_add (f g h : α → β) : f ○ (g + h) = f ○ g + f ○ h := by
  simp_rw [← conv_conjneg, conjneg_add, conv_add]

theorem add_dconv (f g h : α → β) : (f + g) ○ h = f ○ h + g ○ h := by
  simp_rw [← conv_conjneg, add_conv]

theorem smul_conv [DistribSMul γ β] [IsScalarTower γ β β] (c : γ) (f g : α → β) :
    c • f ∗ g = c • (f ∗ g) := by
  ext a <;> simp only [Pi.smul_apply, smul_sum, conv_apply, smul_mul_assoc]

theorem smul_dconv [DistribSMul γ β] [IsScalarTower γ β β] (c : γ) (f g : α → β) :
    c • f ○ g = c • (f ○ g) := by
  ext a <;> simp only [Pi.smul_apply, smul_sum, dconv_apply, smul_mul_assoc]

theorem conv_smul [DistribSMul γ β] [SMulCommClass γ β β] (c : γ) (f g : α → β) :
    f ∗ c • g = c • (f ∗ g) := by
  ext a <;> simp only [Pi.smul_apply, smul_sum, conv_apply, mul_smul_comm]

theorem dconv_smul [Star γ] [DistribSMul γ β] [SMulCommClass γ β β] [StarModule γ β] (c : γ)
    (f g : α → β) : f ○ c • g = star c • (f ○ g) := by
  ext a <;>
    simp only [Pi.smul_apply, smul_sum, dconv_apply, mul_smul_comm, starRingEnd_apply,
      StarModule.star_smul]

alias smul_conv_assoc := smul_conv

alias smul_dconv_assoc := smul_dconv

alias smul_conv_left_comm := conv_smul

alias smul_dconv_left_comm := dconv_smul

theorem hMul_smul_conv_comm [Monoid γ] [DistribMulAction γ β] [IsScalarTower γ β β]
    [SMulCommClass γ β β] (c d : γ) (f g : α → β) : (c * d) • (f ∗ g) = c • f ∗ d • g := by
  rw [smul_conv, conv_smul, mul_smul]

theorem map_conv {γ} [CommSemiring γ] [StarRing γ] (m : β →+* γ) (f g : α → β) (a : α) :
    m ((f ∗ g) a) = (m ∘ f ∗ m ∘ g) a := by simp_rw [conv_apply, map_sum, map_mul]

theorem comp_conv {γ} [CommSemiring γ] [StarRing γ] (m : β →+* γ) (f g : α → β) :
    m ∘ (f ∗ g) = m ∘ f ∗ m ∘ g :=
  funext <| map_conv _ _ _

--TODO: Can we generalise to star ring homs?
theorem map_dconv (f g : α → ℝ≥0) (a : α) : (↑((f ○ g) a) : ℝ) = (coe ∘ f ○ coe ∘ g) a := by
  simp_rw [dconv_apply, NNReal.coe_sum, NNReal.coe_mul, starRingEnd_apply, star_trivial]

theorem conv_eq_sum_sub (f g : α → β) (a : α) : (f ∗ g) a = ∑ t, f (a - t) * g t :=
  by
  rw [conv_apply]
  refine'
      sum_bij (fun x _ => x.2) (fun x _ => mem_univ _) _ _ fun b _ =>
        ⟨(a - b, b), mem_filter.2 ⟨mem_univ _, sub_add_cancel _ _⟩, rfl⟩ <;>
    simp only [mem_filter, mem_univ, true_and_iff, Prod.forall]
  · rintro b c rfl
    rw [add_sub_cancel]
  · rintro b c x h rfl rfl
    simpa [Prod.ext_iff] using h

theorem conv_eq_sum_add (f g : α → β) (a : α) : (f ∗ g) a = ∑ t, f (a + t) * g (-t) :=
  (conv_eq_sum_sub _ _ _).trans <|
    Fintype.sum_equiv (Equiv.neg _) _ _ fun t => by
      simp only [sub_eq_add_neg, Equiv.neg_apply, neg_neg]

theorem dconv_eq_sum_add (f g : α → β) (a : α) : (f ○ g) a = ∑ t, f (a + t) * conj (g t) := by
  simp [← conv_conjneg, conv_eq_sum_add]

theorem conv_eq_sum_sub' (f g : α → β) (a : α) : (f ∗ g) a = ∑ t, f t * g (a - t) := by
  rw [conv_comm, conv_eq_sum_sub] <;> simp_rw [mul_comm]

theorem dconv_eq_sum_sub (f g : α → β) (a : α) : (f ○ g) a = ∑ t, f t * conj (g (t - a)) := by
  simp [← conv_conjneg, conv_eq_sum_sub']

theorem conv_eq_sum_add' (f g : α → β) (a : α) : (f ∗ g) a = ∑ t, f (-t) * g (a + t) := by
  rw [conv_comm, conv_eq_sum_add] <;> simp_rw [mul_comm]

theorem conv_apply_add (f g : α → β) (a b : α) : (f ∗ g) (a + b) = ∑ t, f (a + t) * g (b - t) :=
  (conv_eq_sum_sub _ _ _).trans <|
    Fintype.sum_equiv (Equiv.subLeft b) _ _ fun t => by simp [add_sub_assoc, ← sub_add]

theorem dconv_apply_neg (f g : α → β) (a : α) : (f ○ g) (-a) = conj ((g ○ f) a) := by
  rw [← conjneg_dconv f, conjneg_apply, Complex.conj_conj]

theorem dconv_apply_sub (f g : α → β) (a b : α) :
    (f ○ g) (a - b) = ∑ t, f (a + t) * conj (g (b + t)) := by
  simp [← conv_conjneg, sub_eq_add_neg, conv_apply_add, add_comm]

/- ./././Mathport/Syntax/Translate/Expr.lean:107:6: warning: expanding binder group (a b) -/
theorem sum_conv_hMul (f g h : α → β) : ∑ a, (f ∗ g) a * h a = ∑ (a) (b), f a * g b * h (a + b) :=
  by
  simp_rw [conv_eq_sum_sub', sum_mul]
  rw [sum_comm]
  exact sum_congr rfl fun x _ => Fintype.sum_equiv (Equiv.subRight x) _ _ fun y => by simp

/- ./././Mathport/Syntax/Translate/Expr.lean:107:6: warning: expanding binder group (a b) -/
theorem sum_dconv_hMul (f g h : α → β) :
    ∑ a, (f ○ g) a * h a = ∑ (a) (b), f a * conj (g b) * h (a - b) :=
  by
  simp_rw [dconv_eq_sum_sub, sum_mul]
  rw [sum_comm]
  exact sum_congr rfl fun x _ => Fintype.sum_equiv (Equiv.subLeft x) _ _ fun y => by simp

theorem sum_conv (f g : α → β) : ∑ a, (f ∗ g) a = (∑ a, f a) * ∑ a, g a := by
  simpa only [sum_mul_sum, sum_product, Pi.one_apply, mul_one] using sum_conv_hMul f g 1

theorem sum_dconv (f g : α → β) : ∑ a, (f ○ g) a = (∑ a, f a) * ∑ a, conj (g a) := by
  simpa only [sum_mul_sum, sum_product, Pi.one_apply, mul_one] using sum_dconv_hMul f g 1

@[simp]
theorem conv_const (f : α → β) (b : β) : f ∗ const _ b = const _ ((∑ x, f x) * b) := by
  ext <;> simp [conv_eq_sum_sub', sum_mul]

@[simp]
theorem const_conv (b : β) (f : α → β) : const _ b ∗ f = const _ (b * ∑ x, f x) := by
  ext <;> simp [conv_eq_sum_sub, mul_sum]

@[simp]
theorem dconv_const (f : α → β) (b : β) : f ○ const _ b = const _ ((∑ x, f x) * conj b) := by
  ext <;> simp [dconv_eq_sum_sub, sum_mul]

@[simp]
theorem const_dconv (b : β) (f : α → β) : const _ b ○ f = const _ (b * ∑ x, conj (f x)) := by
  ext <;> simp [dconv_eq_sum_add, mul_sum]

@[simp]
theorem conv_trivChar (f : α → β) : f ∗ trivChar = f := by ext a; simp [conv_eq_sum_sub]

@[simp]
theorem trivChar_conv (f : α → β) : trivChar ∗ f = f := by rw [conv_comm, conv_trivChar]

@[simp]
theorem dconv_trivChar (f : α → β) : f ○ trivChar = f := by ext a; simp [dconv_eq_sum_add]

@[simp]
theorem trivChar_dconv (f : α → β) : trivChar ○ f = conjneg f := by
  rw [← conv_conjneg, trivChar_conv]

theorem support_conv_subset (f g : α → β) : support (f ∗ g) ⊆ support f + support g :=
  by
  rintro a ha
  obtain ⟨x, hx, h⟩ := exists_ne_zero_of_sum_ne_zero ha
  exact ⟨x.1, x.2, left_ne_zero_of_mul h, right_ne_zero_of_mul h, (mem_filter.1 hx).2⟩

theorem support_dconv_subset (f g : α → β) : support (f ○ g) ⊆ support f - support g := by
  simpa [sub_eq_add_neg] using support_conv_subset f (conjneg g)

/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
theorem indicate_conv_indicate_apply (s t : Finset α) (a : α) :
    (𝟭_[β] s ∗ 𝟭 t) a = ((s ×ˢ t).filterₓ fun x : α × α => x.1 + x.2 = a).card :=
  by
  simp only [conv_apply, indicate_apply, ← ite_and, filter_comm, boole_mul, sum_boole]
  simp_rw [← mem_product, filter_mem_univ]

/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
theorem indicate_dconv_indicate_apply (s t : Finset α) (a : α) :
    (𝟭_[β] s ○ 𝟭 t) a = ((s ×ˢ t).filterₓ fun x : α × α => x.1 - x.2 = a).card :=
  by
  simp only [dconv_apply, indicate_apply, ← ite_and, filter_comm, boole_mul, sum_boole,
    apply_ite conj, map_one, map_zero]
  simp_rw [← mem_product, filter_mem_univ]

end CommSemiring

section CommRing

variable [CommRing β] [StarRing β]

@[simp]
theorem conv_neg (f g : α → β) : f ∗ -g = -(f ∗ g) := by ext <;> simp [conv_apply]

@[simp]
theorem neg_conv (f g : α → β) : -f ∗ g = -(f ∗ g) := by ext <;> simp [conv_apply]

@[simp]
theorem dconv_neg (f g : α → β) : f ○ -g = -(f ○ g) := by ext <;> simp [dconv_apply]

@[simp]
theorem neg_dconv (f g : α → β) : -f ○ g = -(f ○ g) := by ext <;> simp [dconv_apply]

theorem conv_sub (f g h : α → β) : f ∗ (g - h) = f ∗ g - f ∗ h := by
  simp only [sub_eq_add_neg, conv_add, conv_neg]

theorem sub_conv (f g h : α → β) : (f - g) ∗ h = f ∗ h - g ∗ h := by
  simp only [sub_eq_add_neg, add_conv, neg_conv]

theorem dconv_sub (f g h : α → β) : f ○ (g - h) = f ○ g - f ○ h := by
  simp only [sub_eq_add_neg, dconv_add, dconv_neg]

theorem sub_dconv (f g h : α → β) : (f - g) ○ h = f ○ h - g ○ h := by
  simp only [sub_eq_add_neg, add_dconv, neg_dconv]

end CommRing

section Semifield

variable [Semifield β] [StarRing β]

@[simp]
theorem mu_univ_conv_mu_univ : μ_[β] (univ : Finset α) ∗ μ univ = μ univ := by
  ext <;> cases eq_or_ne (card α : β) 0 <;> simp [mu_apply, conv_eq_sum_add, card_univ, *]

@[simp]
theorem mu_univ_dconv_mu_univ : μ_[β] (univ : Finset α) ○ μ univ = μ univ := by
  ext <;> cases eq_or_ne (card α : β) 0 <;> simp [mu_apply, dconv_eq_sum_add, card_univ, *]

theorem expect_conv (f g : α → β) : 𝔼 a, (f ∗ g) a = (∑ a, f a) * 𝔼 a, g a := by
  simp_rw [expect, sum_conv, mul_div_assoc]

theorem expect_dconv (f g : α → β) : 𝔼 a, (f ○ g) a = (∑ a, f a) * 𝔼 a, conj (g a) := by
  simp_rw [expect, sum_dconv, mul_div_assoc]

theorem expect_conv' (f g : α → β) : 𝔼 a, (f ∗ g) a = (𝔼 a, f a) * ∑ a, g a := by
  simp_rw [expect, sum_conv, mul_div_right_comm]

theorem expect_dconv' (f g : α → β) : 𝔼 a, (f ○ g) a = (𝔼 a, f a) * ∑ a, conj (g a) := by
  simp_rw [expect, sum_dconv, mul_div_right_comm]

end Semifield

section Field

variable [Field β] [StarRing β] [CharZero β]

@[simp]
theorem balance_conv (f g : α → β) : balance (f ∗ g) = balance f ∗ balance g := by
  simp [balance, conv_sub, sub_conv, expect_conv]

@[simp]
theorem balance_dconv (f g : α → β) : balance (f ○ g) = balance f ○ balance g := by
  simp [balance, dconv_sub, sub_dconv, expect_dconv, map_expect]

end Field

namespace IsROrC

variable {𝕜 : Type} [IsROrC 𝕜] (f g : α → ℝ) (a : α)

@[simp, norm_cast]
theorem coe_conv : (↑((f ∗ g) a) : 𝕜) = (coe ∘ f ∗ coe ∘ g) a :=
  map_conv (algebraMap ℝ 𝕜) _ _ _

@[simp, norm_cast]
theorem coe_dconv : (↑((f ○ g) a) : 𝕜) = (coe ∘ f ○ coe ∘ g) a := by simp [dconv_apply, coe_sum]

@[simp]
theorem coe_comp_conv : (coe : ℝ → 𝕜) ∘ (f ∗ g) = coe ∘ f ∗ coe ∘ g :=
  funext <| coe_conv _ _

@[simp]
theorem coe_comp_dconv : (coe : ℝ → 𝕜) ∘ (f ○ g) = coe ∘ f ○ coe ∘ g :=
  funext <| coe_dconv _ _

end IsROrC

namespace NNReal

variable (f g : α → ℝ≥0) (a : α)

@[simp, norm_cast]
theorem coe_conv : (↑((f ∗ g) a) : ℝ) = (coe ∘ f ∗ coe ∘ g) a :=
  map_conv NNReal.toRealHom _ _ _

@[simp, norm_cast]
theorem coe_dconv : (↑((f ○ g) a) : ℝ) = (coe ∘ f ○ coe ∘ g) a := by simp [dconv_apply, coe_sum]

@[simp]
theorem coe_comp_conv : (coe : _ → ℝ) ∘ (f ∗ g) = coe ∘ f ∗ coe ∘ g :=
  funext <| coe_conv _ _

@[simp]
theorem coe_comp_dconv : (coe : _ → ℝ) ∘ (f ○ g) = coe ∘ f ○ coe ∘ g :=
  funext <| coe_dconv _ _

end NNReal

/-! ### Iterated convolution -/


section CommSemiring

variable [CommSemiring β] [StarRing β] {f g : α → β} {n : ℕ}

/-- Iterated convolution. -/
def iterConv (f : α → β) : ℕ → α → β
  | 0 => trivChar
  | n + 1 => f ∗ iterConv n

infixl:78 " ∗^ " => iterConv

@[simp]
theorem iterConv_zero (f : α → β) : f ∗^ 0 = trivChar :=
  rfl

@[simp]
theorem iterConv_one (f : α → β) : f ∗^ 1 = f :=
  conv_trivChar _

theorem iterConv_succ (f : α → β) (n : ℕ) : f ∗^ (n + 1) = f ∗ f ∗^ n :=
  rfl

theorem iterConv_succ' (f : α → β) (n : ℕ) : f ∗^ (n + 1) = f ∗^ n ∗ f :=
  conv_comm _ _

theorem iterConv_add (f : α → β) (m : ℕ) : ∀ n, f ∗^ (m + n) = f ∗^ m ∗ f ∗^ n
  | 0 => by simp
  | n + 1 => by simp [← add_assoc, iterConv_succ, iterConv_add, conv_left_comm]

theorem iterConv_hMul (f : α → β) (m : ℕ) : ∀ n, f ∗^ (m * n) = f ∗^ m ∗^ n
  | 0 => rfl
  | n + 1 => by simp [mul_add_one, iterConv_succ, iterConv_add, iterConv_hMul]

theorem iterConv_mul' (f : α → β) (m n : ℕ) : f ∗^ (m * n) = f ∗^ n ∗^ m := by
  rw [mul_comm, iterConv_hMul]

@[simp]
theorem conj_iterConv (f : α → β) : ∀ n, conj (f ∗^ n) = conj f ∗^ n
  | 0 => by ext <;> simp
  | n + 1 => by simp [iterConv_succ, conj_iterConv]

@[simp]
theorem conjneg_iterConv (f : α → β) : ∀ n, conjneg (f ∗^ n) = conjneg f ∗^ n
  | 0 => by ext <;> simp
  | n + 1 => by simp [iterConv_succ, conjneg_iterConv]

theorem iterConv_conv_distrib (f g : α → β) : ∀ n, (f ∗ g) ∗^ n = f ∗^ n ∗ g ∗^ n
  | 0 => (conv_trivChar _).symm
  | n + 1 => by simp_rw [iterConv_succ, iterConv_conv_distrib, conv_conv_conv_comm]

theorem iterConv_dconv_distrib (f g : α → β) : ∀ n, (f ○ g) ∗^ n = f ∗^ n ○ g ∗^ n
  | 0 => (dconv_trivChar _).symm
  | n + 1 => by simp_rw [iterConv_succ, iterConv_dconv_distrib, conv_dconv_conv_comm]

@[simp]
theorem zero_iterConv : ∀ {n}, n ≠ 0 → (0 : α → β) ∗^ n = 0
  | 0, hn => by cases hn rfl
  | n + 1, _ => zero_conv _

@[simp]
theorem smul_iterConv [Monoid γ] [DistribMulAction γ β] [IsScalarTower γ β β] [SMulCommClass γ β β]
    (c : γ) (f : α → β) : ∀ n, (c • f) ∗^ n = c ^ n • f ∗^ n
  | 0 => by simp
  | n + 1 => by simp_rw [iterConv_succ, smul_iterConv n, pow_succ, hMul_smul_conv_comm]

theorem comp_iterConv {γ} [CommSemiring γ] [StarRing γ] (m : β →+* γ) (f : α → β) :
    ∀ n, m ∘ (f ∗^ n) = m ∘ f ∗^ n
  | 0 => by ext <;> simp
  | n + 1 => by simp [iterConv_succ, comp_conv, comp_iterConv]

theorem map_iterConv {γ} [CommSemiring γ] [StarRing γ] (m : β →+* γ) (f : α → β) (a : α) (n : ℕ) :
    m ((f ∗^ n) a) = (m ∘ f ∗^ n) a :=
  congr_fun (comp_iterConv m _ _) _

theorem sum_iterConv (f : α → β) : ∀ n, ∑ a, (f ∗^ n) a = (∑ a, f a) ^ n
  | 0 => by simp [filter_eq']
  | n + 1 => by simp only [iterConv_succ, sum_conv, sum_iterConv, pow_succ]

@[simp]
theorem iterConv_trivChar : ∀ n, (trivChar : α → β) ∗^ n = trivChar
  | 0 => rfl
  | n + 1 => (trivChar_conv _).trans <| iterConv_trivChar _

theorem support_iterConv_subset (f : α → β) : ∀ n, support (f ∗^ n) ⊆ n • support f
  | 0 => by
    simp only [iterConv_zero, zero_smul, support_subset_iff, Ne.def, ite_eq_right_iff, not_forall,
      exists_prop, Set.mem_zero, and_imp, forall_eq, eq_self_iff_true, imp_true_iff, trivChar_apply]
  | n + 1 => (support_conv_subset _ _).trans <| Set.add_subset_add_left <| support_iterConv_subset _

theorem indicate_iterConv_apply (s : Finset α) (n : ℕ) (a : α) :
    (𝟭_[ℝ] s ∗^ n) a = ((piFinset fun i => s).filterₓ fun x : Fin n → α => ∑ i, x i = a).card :=
  by
  induction' n with n ih generalizing a
  · simp [apply_ite card, eq_comm]
  simp_rw [iterConv_succ, conv_eq_sum_sub', ih, indicate_apply, boole_mul, sum_ite, filter_mem_univ,
    sum_const_zero, add_zero, ← Nat.cast_sum, ← Finset.card_sigma, Nat.cast_inj]
  refine' Finset.card_congr (fun f _ => Fin.cons f.1 f.2) _ _ _
  · simp only [Fin.sum_cons, eq_sub_iff_add_eq', mem_sigma, mem_filter, mem_pi_finset, and_imp]
    refine' fun bf hb hf ha => ⟨Fin.cases _ _, ha⟩
    · exact hb
    · simpa only [Fin.cons_succ]
  ·
    simp only [Sigma.ext_iff, Fin.cons_eq_cons, heq_iff_eq, imp_self, imp_true_iff, forall_const,
      Sigma.forall]
  · simp only [mem_filter, mem_pi_finset, mem_sigma, exists_prop, Sigma.exists, and_imp,
      eq_sub_iff_add_eq', and_assoc']
    exact fun f hf ha =>
      ⟨f 0, Fin.tail f, hf _, fun _ => hf _, (Fin.sum_univ_succ _).symm.trans ha,
        Fin.cons_self_tail _⟩

end CommSemiring

section Field

variable [Field β] [StarRing β] [CharZero β]

@[simp]
theorem balance_iterConv (f : α → β) : ∀ {n}, n ≠ 0 → balance (f ∗^ n) = balance f ∗^ n
  | 0, h => by cases h rfl
  | 1, h => by simp
  | n + 2, h => by simp [iterConv_succ _ (n + 1), balance_iterConv n.succ_ne_zero]

end Field

namespace NNReal

variable {f : α → ℝ≥0}

@[simp, norm_cast]
theorem coe_iterConv (f : α → ℝ≥0) (n : ℕ) (a : α) : (↑((f ∗^ n) a) : ℝ) = (coe ∘ f ∗^ n) a :=
  map_iterConv NNReal.toRealHom _ _ _

end NNReal

