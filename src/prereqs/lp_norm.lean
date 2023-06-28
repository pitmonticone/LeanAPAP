import analysis.inner_product_space.pi_L2
import mathlib.analysis.normed.group.basic
import mathlib.analysis.normed_space.pi_Lp
import mathlib.analysis.normed_space.ray
import mathlib.analysis.special_functions.pow.real
import mathlib.data.real.basic
import mathlib.data.real.nnreal
import mathlib.order.conditionally_complete_lattice.finset
import prereqs.misc
import prereqs.translate

/-!
# Lp norms
-/

open finset real
open_locale big_operators complex_conjugate ennreal nnreal

variables {ι : Type*} [fintype ι]

/-! ### Lp norm -/

section normed_add_comm_group
variables {α : ι → Type*} [Π i, normed_add_comm_group (α i)] {p : ℝ≥0∞} {f g h : Π i, α i}

/-- The Lp norm of a function. -/
noncomputable def Lpnorm (p : ℝ≥0∞) (f : Π i, α i) : ℝ := ‖(pi_Lp.equiv p _).symm f‖

notation `‖` f `‖_[` p `]` := Lpnorm p f

lemma Lpnorm_eq_sum' (hp : 0 < p.to_real) (f : Π i, α i) :
  ‖f‖_[p] = (∑ i, ‖f i‖ ^ p.to_real) ^ p.to_real⁻¹ :=
by rw ←one_div; exact pi_Lp.norm_eq_sum hp _

lemma Lpnorm_eq_sum'' {p : ℝ} (hp : 0 < p) (f : Π i, α i) :
  ‖f‖_[p.to_nnreal] = (∑ i, ‖f i‖ ^ p) ^ p⁻¹ :=
by rw Lpnorm_eq_sum'; simp [hp, hp.le]

lemma Lpnorm_eq_sum {p : ℝ≥0} (hp : 0 < p) (f : Π i, α i) :
  ‖f‖_[p] = (∑ i, ‖f i‖ ^ (p : ℝ)) ^ (p⁻¹ : ℝ) :=
Lpnorm_eq_sum' hp _

lemma Lpnorm_rpow_eq_sum {p : ℝ≥0} (hp : 0 < p) (f : Π i, α i) :
  ‖f‖_[p] ^ (p : ℝ) = ∑ i, ‖f i‖ ^ (p : ℝ) :=
begin
  rw [Lpnorm_eq_sum hp, rpow_inv_rpow],
  { exact sum_nonneg (λ i _, by positivity) },
  { positivity }
end

lemma Lpnorm_pow_eq_sum {p : ℕ} (hp : p ≠ 0) (f : Π i, α i) : ‖f‖_[p] ^ p = ∑ i, ‖f i‖ ^ p :=
by simpa using Lpnorm_rpow_eq_sum (nat.cast_pos.2 hp.bot_lt) f

lemma L1norm_eq_sum (f : Π i, α i) : ‖f‖_[1] = ∑ i, ‖f i‖ := by simp [Lpnorm_eq_sum']

lemma L0norm_eq_card (f : Π i, α i) : ‖f‖_[0] = {i | f i ≠ 0}.to_finite.to_finset.card :=
pi_Lp.norm_eq_card _

lemma Linftynorm_eq_csupr (f : Π i, α i) : ‖f‖_[∞] = ⨆ i, ‖f i‖ := pi_Lp.norm_eq_csupr _

@[simp] lemma Lpnorm_zero : ‖(0 : Π i, α i)‖_[p] = 0 :=
begin
  cases p, swap,
  obtain rfl | hp := @eq_zero_or_pos _ _ p,
  all_goals { simp [Linftynorm_eq_csupr, L0norm_eq_card, Lpnorm_eq_sum, *, ne_of_gt] },
end

@[simp] lemma Lpnorm_norm (f : Π i, α i) : ‖λ i, ‖f i‖‖_[p] = ‖f‖_[p] :=
begin
  cases p, swap,
  obtain rfl | hp := @eq_zero_or_pos _ _ p,
  all_goals { simp [Linftynorm_eq_csupr, L0norm_eq_card, Lpnorm_eq_sum, *, ne_of_gt] },
end

@[simp] lemma Lpnorm_neg (f : Π i, α i) : ‖-f‖_[p] = ‖f‖_[p] := by simp [←Lpnorm_norm (-f)]

lemma Lpnorm_sub_comm (f g : Π i, α i) : ‖f - g‖_[p] = ‖g - f‖_[p] := by simp [←Lpnorm_neg (f - g)]

@[simp] lemma Lpnorm_nonneg : 0 ≤ ‖f‖_[p] :=
begin
  cases p,
  { simp only [Linftynorm_eq_csupr, ennreal.none_eq_top],
    exact real.supr_nonneg (λ i, norm_nonneg _) },
  obtain rfl | hp := @eq_zero_or_pos _ _ p,
  { simp only [L0norm_eq_card, ennreal.some_eq_coe, ennreal.coe_zero],
    exact nat.cast_nonneg _ },
  { simp only [Lpnorm_eq_sum hp, ennreal.some_eq_coe],
    exact rpow_nonneg_of_nonneg
      (sum_nonneg $ λ i _, rpow_nonneg_of_nonneg (norm_nonneg _) _) _ }
end

@[simp] lemma Lpnorm_eq_zero : ‖f‖_[p] = 0 ↔ f = 0 :=
begin
  cases p,
  { casesI is_empty_or_nonempty ι; simp [Linftynorm_eq_csupr, ennreal.none_eq_top,
      ←sup'_univ_eq_csupr, le_antisymm_iff, function.funext_iff] },
  obtain rfl | hp := @eq_zero_or_pos _ _ p,
  { simp [L0norm_eq_card, eq_empty_iff_forall_not_mem, function.funext_iff] },
  { rw ←rpow_eq_zero Lpnorm_nonneg (nnreal.coe_ne_zero.2 hp.ne'),
    simp [Lpnorm_rpow_eq_sum hp, sum_eq_zero_iff_of_nonneg, rpow_nonneg_of_nonneg,
      rpow_eq_zero _ (nnreal.coe_ne_zero.2 hp.ne'), function.funext_iff] }
end

@[simp] lemma Lpnorm_pos : 0 < ‖f‖_[p] ↔ f ≠ 0 := Lpnorm_nonneg.gt_iff_ne.trans Lpnorm_eq_zero.not

section one_le

lemma Lpnorm_add_le (hp : 1 ≤ p) (f g : Π i, α i) : ‖f + g‖_[p] ≤ ‖f‖_[p] + ‖g‖_[p] :=
by haveI := fact.mk hp; exact norm_add_le _ _

lemma Lpnorm_sub_le (hp : 1 ≤ p) (f g : Π i, α i) : ‖f - g‖_[p] ≤ ‖f‖_[p] + ‖g‖_[p] :=
by haveI := fact.mk hp; exact norm_sub_le _ _

lemma Lpnorm_sub_le_Lpnorm_sub_add_Lpnorm_sub (hp : 1 ≤ p) :
  ‖f - h‖_[p] ≤ ‖f - g‖_[p] + ‖g - h‖_[p] :=
by haveI := fact.mk hp; exact norm_sub_le_norm_sub_add_norm_sub

variables {𝕜 : Type*} [normed_field 𝕜] [Π i, normed_space 𝕜 (α i)]

-- TODO: `p ≠ 0` is enough
lemma Lpnorm_smul (hp : 1 ≤ p) (c : 𝕜) (f : Π i, α i) : ‖c • f‖_[p] = ‖c‖ * ‖f‖_[p] :=
by haveI := fact.mk hp; exact norm_smul _ _

-- TODO: Why is it so hard to use `Lpnorm_smul` directly? `function.has_smul` seems to have a hard
-- time unifying `pi.has_smul`
lemma Lpnorm_smul' {α : Type*} [normed_add_comm_group α] [normed_space 𝕜 α] (hp : 1 ≤ p) (c : 𝕜)
  (f : ι → α) : ‖c • f‖_[p] = ‖c‖ * ‖f‖_[p] :=
Lpnorm_smul hp _ _

variables [Π i, normed_space ℝ (α i)]

lemma Lpnorm_nsmul (hp : 1 ≤ p) (n : ℕ) (f : Π i, α i) : ‖n • f‖_[p] = n • ‖f‖_[p] :=
by haveI := fact.mk hp; exact norm_nsmul _ _

-- TODO: Why is it so hard to use `Lpnorm_nsmul` directly? `function.has_smul` seems to have a hard
-- time unifying `pi.has_smul`
lemma Lpnorm_nsmul' {α : Type*} [normed_add_comm_group α] [normed_space ℝ α] (hp : 1 ≤ p) (n : ℕ)
  (f : ι → α) : ‖n • f‖_[p] = n • ‖f‖_[p] :=
Lpnorm_nsmul hp _ _

end one_le
end normed_add_comm_group

lemma Lpnorm_mono {p : ℝ≥0} {f g : ι → ℝ} (hf : 0 ≤ f) (hfg : f ≤ g) : ‖f‖_[p] ≤ ‖g‖_[p] :=
begin
  obtain rfl | hp := @eq_zero_or_pos _ _ p,
  { simp only [L0norm_eq_card, ennreal.some_eq_coe, ennreal.coe_zero, nat.cast_le],
    exact card_mono
      (set.finite.to_finset_mono $ λ i, mt $ λ hi, ((hfg i).trans_eq hi).antisymm $ hf i) },
  rw ←nnreal.coe_pos at hp,
  simp_rw [←rpow_le_rpow_iff Lpnorm_nonneg Lpnorm_nonneg hp, Lpnorm_rpow_eq_sum hp,
    norm_of_nonneg (hf _), norm_of_nonneg (hf.trans hfg _)],
  exact sum_le_sum (λ i _, rpow_le_rpow (hf _) (hfg _) hp.le),
end

/-! #### Weighted Lp norm -/

section normed_add_comm_group
variables {α : ι → Type*} [Π i, normed_add_comm_group (α i)] {p : ℝ≥0} {w : ι → ℝ≥0}
  {f g h : Π i, α i}

/-- The weighted Lp norm of a function. -/
noncomputable def wLpnorm (p : ℝ≥0) (w : ι → ℝ≥0) (f : Π i, α i) : ℝ :=
‖(λ i, w i ^ (p⁻¹ : ℝ) • ‖f i‖)‖_[p]

notation `‖` f `‖_[` p `, ` w `]` := wLpnorm p w f

@[simp] lemma wLpnorm_one (p : ℝ≥0) (f : Π i, α i) : ‖f‖_[p, 1] = ‖f‖_[p] :=
by obtain rfl | hp := @eq_zero_or_pos _ _ p; simp [wLpnorm, L0norm_eq_card, Lpnorm_eq_sum, *]

lemma wLpnorm_eq_sum (hp : 0 < p) (w : ι → ℝ≥0) (f : Π i, α i) :
  ‖f‖_[p, w] = (∑ i, w i • ‖f i‖ ^ (p : ℝ)) ^ (p⁻¹ : ℝ) :=
begin
  have : (p : ℝ) ≠ 0 := by positivity,
  simp_rw [wLpnorm, Lpnorm_eq_sum hp, nnreal.smul_def, norm_smul],
  simp only [nnreal.coe_rpow, norm_norm, algebra.id.smul_eq_mul, mul_rpow, norm_nonneg,
    rpow_nonneg_of_nonneg, hp.ne', nnreal.coe_nonneg, norm_of_nonneg, rpow_inv_rpow _ this],
end

lemma wLpnorm_eq_sum' {p : ℝ} (hp : 0 < p) (w : ι → ℝ≥0) (f : Π i, α i) :
  ‖f‖_[p.to_nnreal, w] = (∑ i, w i • ‖f i‖ ^ p) ^ p⁻¹ :=
by rw wLpnorm_eq_sum; simp [hp, hp.le]

lemma wLpnorm_rpow_eq_sum {p : ℝ≥0} (hp : 0 < p) (w : ι → ℝ≥0) (f : Π i, α i) :
  ‖f‖_[p, w] ^ (p : ℝ) = ∑ i, w i • ‖f i‖ ^ (p : ℝ) :=
begin
  rw [wLpnorm_eq_sum hp, rpow_inv_rpow],
  { exact sum_nonneg (λ i _, by positivity) },
  { positivity }
end

lemma wLpnorm_pow_eq_sum {p : ℕ} (hp : p ≠ 0) (w : ι → ℝ≥0) (f : Π i, α i) :
  ‖f‖_[p, w] ^ p = ∑ i, w i • ‖f i‖ ^ p :=
by simpa using wLpnorm_rpow_eq_sum (nat.cast_pos.2 hp.bot_lt) w f

lemma wL1norm_eq_sum (w : ι → ℝ≥0) (w : ι → ℝ≥0) (f : Π i, α i) : ‖f‖_[1, w] = ∑ i, w i • ‖f i‖ :=
by simp [wLpnorm_eq_sum]

lemma wL0norm_eq_card (w : ι → ℝ≥0) (f : Π i, α i) :
  ‖f‖_[0, w] = {i | f i ≠ 0}.to_finite.to_finset.card :=
by simp [wLpnorm, L0norm_eq_card]

@[simp] lemma wLpnorm_zero (w : ι → ℝ≥0) : ‖(0 : Π i, α i)‖_[p, w] = 0 :=
by simp [wLpnorm, ←pi.zero_def]

@[simp] lemma wLpnorm_norm (w : ι → ℝ≥0) (f : Π i, α i) : ‖λ i, ‖f i‖‖_[p, w] = ‖f‖_[p, w] :=
by obtain rfl | hp := @eq_zero_or_pos _ _ p; simp [wL0norm_eq_card, wLpnorm_eq_sum, *, ne_of_gt]

@[simp] lemma wLpnorm_neg (w : ι → ℝ≥0) (f : Π i, α i) : ‖-f‖_[p, w] = ‖f‖_[p, w] :=
by simp [←wLpnorm_norm _ (-f)]

lemma wLpnorm_sub_comm (w : ι → ℝ≥0) (f g : Π i, α i) : ‖f - g‖_[p, w] = ‖g - f‖_[p, w] :=
by simp [←wLpnorm_neg _ (f - g)]

@[simp] lemma wLpnorm_nonneg : 0 ≤ ‖f‖_[p, w] := Lpnorm_nonneg

section one_le

lemma wLpnorm_add_le (hp : 1 ≤ p) (w : ι → ℝ≥0) (f g : Π i, α i) :
  ‖f + g‖_[p, w] ≤ ‖f‖_[p, w] + ‖g‖_[p, w] :=
begin
  unfold wLpnorm,
  refine (Lpnorm_add_le (by exact_mod_cast hp ) _ _).trans'
    (Lpnorm_mono (λ i, by dsimp; positivity) $ λ i, _),
  dsimp,
  rw ←smul_add,
  exact smul_le_smul_of_nonneg (norm_add_le _ _) (zero_le _),
end

lemma wLpnorm_sub_le (hp : 1 ≤ p) (w : ι → ℝ≥0) (f g : Π i, α i) :
  ‖f - g‖_[p, w] ≤ ‖f‖_[p, w] + ‖g‖_[p, w] :=
by simpa [sub_eq_add_neg] using wLpnorm_add_le hp w f (-g)

lemma wLpnorm_sub_le_Lpnorm_sub_add_Lpnorm_sub (hp : 1 ≤ p) :
  ‖f - h‖_[p, w] ≤ ‖f - g‖_[p, w] + ‖g - h‖_[p, w] :=
by simpa using wLpnorm_add_le hp w (f - g) (g - h)

variables {𝕜 : Type*} [normed_field 𝕜] [Π i, normed_space 𝕜 (α i)]

-- TODO: `p ≠ 0` is enough
lemma wLpnorm_smul (hp : 1 ≤ p) (c : 𝕜) (f : Π i, α i) : ‖c • f‖_[p, w] = ‖c‖ * ‖f‖_[p, w] :=
sorry -- TODO: Bhavik

-- TODO: Why is it so hard to use `wLpnorm_smul` directly? `function.has_smul` seems to have a hard
-- time unifying `pi.has_smul`
lemma wLpnorm_smul' {α : Type*} [normed_add_comm_group α] [normed_space 𝕜 α] (hp : 1 ≤ p) (c : 𝕜)
  (f : ι → α) : ‖c • f‖_[p, w] = ‖c‖ * ‖f‖_[p, w] :=
Lpnorm_smul hp _ _

variables [Π i, normed_space ℝ (α i)]

lemma wLpnorm_nsmul (hp : 1 ≤ p) (n : ℕ) (w : ι → ℝ≥0) (f : Π i, α i) :
  ‖n • f‖_[p, w] = n • ‖f‖_[p, w] :=
by rw [nsmul_eq_smul_cast ℝ, wLpnorm_smul hp, is_R_or_C.norm_nat_cast, nsmul_eq_mul]

-- TODO: Why is it so hard to use `wLpnorm_nsmul` directly? `function.has_smul` seems to have a hard
-- time unifying `pi.has_smul`
lemma wLpnorm_nsmul' {α : Type*} [normed_add_comm_group α] [normed_space ℝ α] (hp : 1 ≤ p) (n : ℕ)
  (w : ι → ℝ≥0) (f : ι → α) : ‖n • f‖_[p, w] = n • ‖f‖_[p, w] :=
wLpnorm_nsmul hp _ _ _

end one_le
end normed_add_comm_group

lemma wLpnorm_mono {p : ℝ≥0} {w : ι → ℝ≥0} {f g : ι → ℝ} (hf : 0 ≤ f) (hfg : f ≤ g) :
  ‖f‖_[p, w] ≤ ‖g‖_[p, w] :=
Lpnorm_mono (λ i, by dsimp; positivity) $ λ i, smul_le_smul_of_nonneg
  (by rw [norm_of_nonneg (hf _), norm_of_nonneg (hf.trans hfg _)]; exact hfg _) $ by positivity

/-! #### Inner product -/

section normed_add_comm_group
variables {α : ι → Type*} [Π i, normed_add_comm_group (α i)] (𝕜 : Type*) [is_R_or_C 𝕜]
  [Π i, inner_product_space 𝕜 (α i)]

@[reducible] noncomputable def L2inner (f g : Π i, α i) : 𝕜 :=
inner ((pi_Lp.equiv 2 _).symm f) ((pi_Lp.equiv 2 _).symm g)

notation `⟪`f`, `g`⟫_[`𝕜`]` := L2inner 𝕜 f g

lemma L2inner_eq_sum (f g : Π i, α i) : ⟪f, g⟫_[𝕜] = ∑ i, inner (f i) (g i) := pi_Lp.inner_apply _ _

end normed_add_comm_group

section Lpnorm
variables {α β : Type*} [add_comm_group α] [fintype α] [normed_add_comm_group β] {p : ℝ≥0∞}

@[simp] lemma Lpnorm_translate (a : α) (f : α → β) : ‖τ a f‖_[p] = ‖f‖_[p] :=
begin
  cases p,
  { simp only [Linftynorm_eq_csupr, ennreal.none_eq_top, translate_apply],
    exact (equiv.sub_right _).supr_congr (λ _, rfl) },
  obtain rfl | hp := @eq_zero_or_pos _ _ p,
  { simp only [L0norm_eq_card, translate_apply, ne.def, ennreal.some_eq_coe, ennreal.coe_zero,
      nat.cast_inj],
    exact card_congr (λ x _, x - a) (λ x hx, by simpa using hx)
      (λ x y _ _ h, by simpa using h) (λ x hx, ⟨x + a, by simpa using hx⟩) },
  { simp only [Lpnorm_eq_sum hp, ennreal.some_eq_coe, translate_apply],
    congr' 1,
    exact fintype.sum_equiv (equiv.sub_right _) _ _ (λ _, rfl) }
end

end Lpnorm

/-! ### Hölder inequality -/

section Lpnorm
variables {α : Type*} [fintype α]

/-- Hölder's inequality, binary case. -/
lemma Lpnorm_mul_le (p q r : ℝ≥0∞) (hpqr : p⁻¹ + q⁻¹ = r⁻¹) (f g : α → ℂ) :
  ‖f * g‖_[r] ≤ ‖f‖_[p] * ‖g‖_[q] :=
begin
  sorry, --TODO: Bhavik
end

/-- Hölder's inequality, finitary case. -/
lemma Lpnorm_prod_le {s : finset ι} (p : ι → ℝ≥0∞) (q : ℝ≥0∞) (hpq : ∑ i in s, (p i)⁻¹ = q⁻¹)
  (f : ι → α → ℂ) : ‖∏ i in s, f i‖_[q] ≤ ∏ i in s, ‖f i‖_[p i] :=
begin
  classical,
  induction s using finset.induction with i s hi ih,
  sorry { simp },
  sorry --TODO: Bhavik
end

end Lpnorm

/-! ### Indicator -/

section mu
variables {α : Type*} [fintype α] [decidable_eq α] {s : finset α} {p : ℝ≥0}

lemma Lpnorm_mu (hp : 1 ≤ p) (hs : s.nonempty) : ‖mu s‖_[p] = s.card ^ (p⁻¹ - 1 : ℝ) :=
begin
  have : (s.card : ℝ) ≠ 0 := nat.cast_ne_zero.2 hs.card_pos.ne',
  rw [mu, Lpnorm_smul'], swap,
  { exact_mod_cast hp },
  replace hp := zero_lt_one.trans_le hp,
  simp only [map_inv₀, complex.abs_cast_nat, smul_eq_mul, Lpnorm_eq_sum hp, complex.norm_eq_abs],
  have : ∀ x, (ite (x ∈ s) 1 0 : ℝ) ^ (p : ℝ) = ite (x ∈ s) (1 ^ (p : ℝ)) (0 ^ (p : ℝ)) :=
    λ x, by split_ifs; simp,
  simp_rw [apply_ite complex.abs, map_one, map_zero, this, zero_rpow
    (nnreal.coe_ne_zero.2 hp.ne'), one_rpow, sum_boole, filter_mem_eq_inter,
    univ_inter, rpow_sub_one ‹_›, inv_mul_eq_div],
end

lemma Lpnorm_mu_le (hp : 1 ≤ p) : ‖mu s‖_[p] ≤ s.card ^ (p⁻¹ - 1 : ℝ) :=
begin
  obtain rfl | hs := s.eq_empty_or_nonempty,
  { simp,
    positivity },
  { exact (Lpnorm_mu hp hs).le }
end

lemma L1norm_mu (hs : s.nonempty) : ‖mu s‖_[1] = 1 := by simpa using Lpnorm_mu le_rfl hs

lemma L1norm_mu_le_one : ‖mu s‖_[1] ≤ 1 := by simpa using Lpnorm_mu_le le_rfl

end mu