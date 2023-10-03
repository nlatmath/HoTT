Require Import Basics Types WildCat Join.Core.

(** * We show that the iterated join satisfies symmetrical induction and recursion principles and prove that the recursion principle gives an equivalence of 0-groupoids.  We use this in JoinAssoc.v to prove that the join is associative.  Our approach parallels what is done in the two-variable case in Join/Core.v, especially starting with [TriJoinRecData] here and [JoinRecData] there.  That case is much simpler, so should be read first. *)

Section TriJoinStructure.
  Context {A B C : Type}.

  Definition TriJoin := Join A (Join B C).

  Definition join1 : A -> TriJoin := joinl.
  Definition join2 : B -> TriJoin := fun b => (joinr (joinl b)).
  Definition join3 : C -> TriJoin := fun c => (joinr (joinr c)).
  Definition join12 : forall a b, join1 a = join2 b := fun a b => jglue a (joinl b).
  Definition join13 : forall a c, join1 a = join3 c := fun a c => jglue a (joinr c).
  Definition join23 : forall b c, join2 b = join3 c := fun b c => ap joinr (jglue b c).
  Definition join123 : forall a b c, join12 a b @ join23 b c = join13 a c := fun a b c => triangle_v' a (jglue b c).
End TriJoinStructure.

Arguments TriJoin A B C : clear implicits.

(** * The goal of the next few results is to define [ap_trijoin] and [ap_trijoin_transport]. *)

(** Functions send triangles to triangles. *)
Definition ap_triangle {X Y} (f : X -> Y)
  {a b c : X} {ab : a = b} {bc : b = c} {ac : a = c} (abc : ab @ bc = ac)
  : ap f ab @ ap f bc = ap f ac
  := (ap_pp f ab bc)^ @ ap (ap f) abc.

(** This general result abstracts away the situation where [J] is [TriJoin A B C], [a] is [joinl a'] for some [a'], [jr] is [joinr : Join B C -> J], [jg] is [fun w => jglue a' w], and [p] is [jglue b c].  By working in this generality, we can do induction on [p].  This also allows us to inline the proof of [triangle_v']. *)
Definition ap_trijoin_general {J W P : Type} (f : J -> P)
  (a : J) (jr : W -> J) (jg : forall w, a = jr w)
  {b c : W} (p : b = c)
  : ap f (jg b) @ ap f (ap jr p) = ap f (jg c).
Proof.
  apply ap_triangle.
  induction p.
  apply concat_p1.
Defined.

(** Functions send the canonical triangles in triple joins to triangles. *)
Definition ap_trijoin {A B C P : Type} (f : TriJoin A B C -> P)
  (a : A) (b : B) (c : C)
  : ap f (join12 a b) @ ap f (join23 b c) = ap f (join13 a c).
Proof.
  nrapply ap_trijoin_general.
Defined.

Definition ap_trijoin_general_transport {J W P : Type} (f : J -> P)
  (a : J) (jr : W -> J) (jg : forall w, a = jr w)
  {b c : W} (p : b = c)
  : ap_trijoin_general f a jr jg p
    = (1 @@ ap_compose _ f _)^ @ (transport_paths_Fr _ _)^ @ apD (fun x => ap f (jg x)) p.
Proof.
  induction p.
  unfold ap_trijoin_general; simpl.
  induction (jg b).
  reflexivity.
Defined.

Definition ap_trijoin_transport {A B C P : Type} (f : TriJoin A B C -> P)
  (a : A) (b : B) (c : C)
  : ap_trijoin f a b c
    = (1 @@ ap_compose _ f _)^ @ (transport_paths_Fr _ _)^ @ apD (fun x => ap f (jglue a x)) (jglue b c).
Proof.
  nrapply ap_trijoin_general_transport.
Defined.

(** * Now we prove the induction principle for the triple join. *)

(** A lemma that handles the path algebra in the final step. *)
Local Definition trijoin_ind_helper {A BC : Type} (P : Join A BC -> Type)
  (a : A) (b c : BC) (bc : b = c)
  (j1' : P (joinl a)) (j2' : P (joinr b)) (j3' : P (joinr c))
  (j12' : jglue a b # j1' = j2') (j13' : jglue a c # j1' = j3') (j23' : (ap joinr bc) # j2' = j3')
  (j123' : transport_pp _ (jglue a b) (ap joinr bc) j1' @ ap (transport _ (ap joinr bc)) j12' @ j23'
           = transport2 _ (triangle_v' a bc) _ @ j13')
  : ((apD (fun x : BC => transport P (jglue a x) j1') bc)^
       @ ap (transport (fun x : BC => P (joinr x)) bc) j12')
      @ ((transport_compose P joinr bc j2') @ j23') = j13'.
Proof.
  induction bc; simpl.
  rewrite transport_pp_1 in j123'.
  cbn in *.
  unfold transport; unfold transport in j123'.
  rewrite ap_idmap; rewrite ap_idmap in j123'.
  rewrite concat_pp_p in j123'.
  apply cancelL in j123'.
  rewrite 2 concat_1p.
  exact j123'.
Qed.

(** An induction principle for the triple join. Note that the hypotheses are phrased completely in terms of the "constructors" of [TriJoin A B C]. *)
Definition trijoin_ind (A B C : Type) (P : TriJoin A B C -> Type)
  (join1' : forall a, P (join1 a))
  (join2' : forall b, P (join2 b))
  (join3' : forall c, P (join3 c))
  (join12' : forall a b, join12 a b # join1' a = join2' b)
  (join13' : forall a c, join13 a c # join1' a = join3' c)
  (join23' : forall b c, join23 b c # join2' b = join3' c)
  (join123' : forall a b c, transport_pp _ (join12 a b) (join23 b c) (join1' a)
                         @ ap (transport _ (join23 b c)) (join12' a b) @ join23' b c
                       = transport2 _ (join123 a b c) _ @ join13' a c)
  : forall x, P x.
Proof.
  snrapply Join_ind.
  - exact join1'.
  - snrapply Join_ind.
    + exact join2'.
    + exact join3'.
    + intros b c.
      lhs rapply (transport_compose P).
      apply join23'.
  - intro a.
    snrapply Join_ind.
    + simpl. exact (join12' a).
    + simpl. exact (join13' a).
    + intros b c; cbn beta zeta.
      lhs nrapply (transport_paths_FlFr_D (jglue b c)).
      lhs nrapply (1 @@ _).
      1: nrapply Join_ind_beta_jglue.
      apply trijoin_ind_helper, join123'.
Defined.

(** * We now state the recursion principle and prove many things about it. *)

(** We'll bundle up the arguments into a record. *)
Record TriJoinRecData {A B C P : Type} := {
    j1 : A -> P;
    j2 : B -> P;
    j3 : C -> P;
    j12 : forall a b, j1 a = j2 b;
    j13 : forall a c, j1 a = j3 c;
    j23 : forall b c, j2 b = j3 c;
    j123 : forall a b c, j12 a b @ j23 b c = j13 a c;
  }.

Arguments TriJoinRecData : clear implicits.
Arguments Build_TriJoinRecData {A B C P}%type_scope (j1 j2 j3 j12 j13 j23 j123)%function_scope.

Definition trijoin_rec {A B C P : Type} (f : TriJoinRecData A B C P)
  : TriJoin A B C -> P.
Proof.
  snrapply Join_rec.
  - exact (j1 f).
  - snrapply Join_rec.
    + exact (j2 f).
    + exact (j3 f).
    + exact (j23 f).
  - intro a.
    snrapply Join_ind; cbn beta.
    + exact (j12 f a).
    + exact (j13 f a).
    + intros b c.
      lhs nrapply transport_paths_Fr.
      exact (1 @@ Join_rec_beta_jglue _ _ _ _ _ @ j123 f a b c).
Defined.

(** Beta rules for the recursion principle. *)
Definition trijoin_rec_beta_join12 {A B C P : Type} (f : TriJoinRecData A B C P) (a : A) (b : B)
  : ap (trijoin_rec f) (join12 a b) = j12 f a b
  := Join_rec_beta_jglue _ _ _ _ _.

Definition trijoin_rec_beta_join13 {A B C P : Type} (f : TriJoinRecData A B C P) (a : A) (c : C)
  : ap (trijoin_rec f) (join13 a c) = j13 f a c
  := Join_rec_beta_jglue _ _ _ _ _.

Definition trijoin_rec_beta_join23 {A B C P : Type} (f : TriJoinRecData A B C P) (b : B) (c : C)
  : ap (trijoin_rec f) (join23 b c) = j23 f b c.
Proof.
  unfold trijoin_rec, join23.
  lhs_V nrapply (ap_compose joinr); simpl.
  apply Join_rec_beta_jglue.
Defined.

Local Lemma trijoin_rec_beta_join123_helper {A : Type} {x y z : A}
  {u0 u1 : x = y} {p0 p1 r1 : y = z} {q0 s1 t1 : x = z}
  (p : p0 = p1) (q : q0 = u0 @ p0) (r : p0 = r1)
  (s : u1 @ r1 = s1) (t : s1 = t1) (u : u0 = u1)
  : ((1 @@ p)^ @ q^) @ (((q @ (u @@ 1)) @ ((1 @@ r) @ s)) @ t)
    = ((u @@ (p^ @ r)) @ s) @ t.
Proof.
  induction u, t, s, r, p.
  revert q0 q; by apply paths_ind_r.
Defined.

Definition trijoin_rec_beta_join123 {A B C P : Type} (f : TriJoinRecData A B C P)
  (a : A) (b : B) (c : C)
  : ap_trijoin (trijoin_rec f) a b c
    = (trijoin_rec_beta_join12 f a b @@ trijoin_rec_beta_join23 f b c)
        @ j123 f a b c @ (trijoin_rec_beta_join13 f a c)^.
Proof.
  (* Expand the LHS: *)
  lhs nrapply ap_trijoin_transport.
  rewrite (apD_homotopic (Join_rec_beta_jglue _ _ _ _) (jglue b c)).
  rewrite Join_ind_beta_jglue.
  (* Change [ap (transport __) _] on LHS. *)
  rewrite (concat_p_pp _ (transport_paths_Fr (jglue b c) (j12 f a b)) _).
  rewrite (concat_Ap (transport_paths_Fr (jglue b c))).
  (* [trijoin_rec_beta_join23] expands to something of the form [p^ @ r], so that's what is in the lemma.  One can unfold it to see this, but the [Qed] is a bit faster without this.
  unfold trijoin_rec_beta_join23. *)
  (* Note that one of the [ap]s on the LHS computes to [u @@ 1], so that's what is in the lemma: *)
  (* change (ap (fun q => q @ ?x) ?u) with (u @@ @idpath _ x). *)
  (* Everything that remains is pure path algebra. *)
  nrapply trijoin_rec_beta_join123_helper.
Qed.

(** * We're next going to define a map in the other direction.  We do it via showing that [TriJoinRecData] is a 0-coherent 1-functor to [Type]. We'll later show that it is a 1-functor to 0-groupoids. *)
Definition trijoinrecdata_fun {A B C P Q : Type} (g : P -> Q) (f : TriJoinRecData A B C P)
  : TriJoinRecData A B C Q.
Proof.
  snrapply Build_TriJoinRecData.
  - exact (g o j1 f).
  - exact (g o j2 f).
  - exact (g o j3 f).
  - exact (fun a b => ap g (j12 f a b)).
  - exact (fun a c => ap g (j13 f a c)).
  - exact (fun b c => ap g (j23 f b c)).
  - intros a b c; cbn beta.
    exact (ap_triangle g (j123 f a b c)).
  (* The last four goals above can also be handled by the induction tactics below, but it's useful to be concrete. *)
Defined.

(** The triple join itself has canonical [TriJoinRecData]. *)
Definition trijoinrecdata_trijoin (A B C : Type)
  : TriJoinRecData A B C (Join A (Join B C))
  := Build_TriJoinRecData join1 join2 join3 join12 join13 join23 join123.

(** Combining these gives a function going in the opposite direction to [trijoin_rec]. *)
Definition trijoin_rec_inv {A B C P : Type} (f : TriJoin A B C -> P)
  : TriJoinRecData A B C P
  := trijoinrecdata_fun f (trijoinrecdata_trijoin A B C).

(** * Under [Funext], [trijoin_rec] and [trijoin_rec_inv] should be inverse equivalences.  We'll avoid [Funext] and show that they are equivalences of 0-groupoids, where we choose the path structures carefully.  We begin by describing a notion of paths between elements of [TriJoinRecData A B C P]. *)

(** The type of fillers for a triangular prism with five 2d faces [abc], [abc'], [k12], [k13], [k23]. *)
Definition prism {P : Type}
  {a b c : P} {ab : a = b} {ac : a = c} {bc : b = c} (abc : ab @ bc = ac)
  {a' b' c' : P} {ab' : a' = b'} {ac' : a' = c'} {bc' : b' = c'} (abc' : ab' @ bc' = ac')
  {k1 : a = a'} {k2 : b = b'} {k3 : c = c'}
  (k12 : ab @ k2 = k1 @ ab') (k13 : ac @ k3 = k1 @ ac') (k23 : bc @ k3 = k2 @ bc')
  := concat_p_pp _ _ _ @ whiskerR abc k3 @ k13
    = whiskerL ab k23
    @ concat_p_pp _ _ _ @ whiskerR k12 bc'
    @ concat_pp_p _ _ _ @ whiskerL k1 abc'.

(** The "identity" filler is slightly non-trivial, because the fillers for the squares, e.g. [ab @ 1 = 1 @ ab], must be non-trivial. *)
Definition prism_id {P : Type}
  {a b c : P} {ab : a = b} {ac : a = c} {bc : b = c} (abc : ab @ bc = ac)
  : prism abc abc (equiv_p1_1q idpath) (equiv_p1_1q idpath) (equiv_p1_1q idpath).
Proof.
  induction ab, bc, abc; simpl.
  reflexivity.
Defined.

(** The paths between elements of [TriJoinRecData A B C P].  Under [Funext], this type will be equivalent to the identity type.  But without [Funext], this definition will be more useful. *)
Record TriJoinRecPath {A B C P : Type} {f g : TriJoinRecData A B C P} := {
    h1 : forall a, j1 f a = j1 g a;
    h2 : forall b, j2 f b = j2 g b;
    h3 : forall c, j3 f c = j3 g c;
    h12 : forall a b, j12 f a b @ h2 b = h1 a @ j12 g a b;
    h13 : forall a c, j13 f a c @ h3 c = h1 a @ j13 g a c;
    h23 : forall b c, j23 f b c @ h3 c = h2 b @ j23 g b c;
    h123 : forall a b c, prism (j123 f a b c) (j123 g a b c) (h12 a b) (h13 a c) (h23 b c);
  }.

Arguments TriJoinRecPath {A B C P} f g.

(** We also define data for [trijoin_rec] that unbundles the first three components.  This lets us talk about paths between two such when the first three components are definitionally equal. This is a common special case, and this set-up greatly simplifies a lot of path algebra in later proofs. *)
Record TriJoinRecData' {A B C P : Type} {j1' : A -> P} {j2' : B -> P} {j3' : C -> P} := {
    j12' : forall a b, j1' a = j2' b;
    j13' : forall a c, j1' a = j3' c;
    j23' : forall b c, j2' b = j3' c;
    j123' : forall a b c, j12' a b @ j23' b c = j13' a c;
  }.

Arguments TriJoinRecData' {A B C P} j1' j2' j3'.
Arguments Build_TriJoinRecData' {A B C P}%type_scope
  (j1' j2' j3' j12' j13' j23' j123')%function_scope.

Definition prism' {P : Type} {a b c : P}
  {ab : a = b} {ac : a = c} {bc : b = c} (abc : ab @ bc = ac)
  {ab' : a = b} {ac' : a = c} {bc' : b = c} (abc' : ab' @ bc' = ac')
  (k12 : ab = ab') (k13 : ac = ac') (k23 : bc = bc')
  := abc @ k13 = (k12 @@ k23) @ abc'.

Record TriJoinRecPath' {A B C P : Type} {j1' : A -> P} {j2' : B -> P} {j3' : C -> P}
  {f g : TriJoinRecData' j1' j2' j3'} := {
    h12' : forall a b, j12' f a b = j12' g a b;
    h13' : forall a c, j13' f a c = j13' g a c;
    h23' : forall b c, j23' f b c = j23' g b c;
    h123' : forall a b c, prism' (j123' f a b c) (j123' g a b c) (h12' a b) (h13' a c) (h23' b c);
  }.

Arguments TriJoinRecPath' {A B C P} {j1' j2' j3'} f g.

(** * We can bundle and unbundle these types of data.  For unbundling, we just handle [TriJoinRecData] for now. *)

Definition bundle_trijoinrecdata {A B C P : Type} {j1' : A -> P} {j2' : B -> P} {j3' : C -> P}
  (f : TriJoinRecData' j1' j2' j3')
  : TriJoinRecData A B C P
  := Build_TriJoinRecData j1' j2' j3' (j12' f) (j13' f) (j23' f) (j123' f).

Definition unbundle_trijoinrecdata {A B C P : Type} (f : TriJoinRecData A B C P)
  : TriJoinRecData' (j1 f) (j2 f) (j3 f)
  := Build_TriJoinRecData' (j1 f) (j2 f) (j3 f) (j12 f) (j13 f) (j23 f) (j123 f).

(** The proof by induction that is easily available to us here is what saves work in more complicated contexts. *)
Definition bundle_prism {P : Type} {a b c : P}
  {ab : a = b} {ac : a = c} {bc : b = c} (abc : ab @ bc = ac)
  {ab' : a = b} {ac' : a = c} {bc' : b = c} (abc' : ab' @ bc' = ac')
  (k12 : ab = ab') (k13 : ac = ac') (k23 : bc = bc')
  (k123 : prism' abc abc' k12 k13 k23)
  : prism abc abc' (equiv_p1_1q k12) (equiv_p1_1q k13) (equiv_p1_1q k23).
Proof.
  induction ab.
  induction bc.
  induction abc.
  induction k12.
  induction k23.
  induction k13.
  unfold prism' in k123.
  induction (moveR_Vp _ _ _ k123); clear k123.
  simpl.
  reflexivity.
Defined.

Definition bundle_trijoinrecpath {A B C P : Type} {j1' : A -> P} {j2' : B -> P} {j3' : C -> P}
  {f g : TriJoinRecData' j1' j2' j3'} (h : TriJoinRecPath' f g)
  : TriJoinRecPath (bundle_trijoinrecdata f) (bundle_trijoinrecdata g).
Proof.
  snrapply Build_TriJoinRecPath.
  1, 2, 3: reflexivity.
  1, 2, 3: intros; apply equiv_p1_1q.
  - apply (h12' h).
  - apply (h13' h).
  - apply (h23' h).
  - cbn beta zeta.
    intros a b c.
    apply bundle_prism, (h123' h).
Defined.

(** A tactic that helps us apply the previous result. *)
Ltac bundle_trijoinrecpath :=
  hnf;
  match goal with |- TriJoinRecPath ?F ?G =>
    refine (bundle_trijoinrecpath (f:=unbundle_trijoinrecdata F)
                                  (g:=unbundle_trijoinrecdata G) _) end;
  snrapply Build_TriJoinRecPath'.

(** Using these paths, we can restate the beta rule for [trijoin_rec].  The statement using [TriJoinRecPath'] typechecks only because [trijoin_rec] computes definitionally on the path constructors. *)
Definition trijoin_rec_beta' {A B C P : Type} (f : TriJoinRecData A B C P)
  : TriJoinRecPath' (unbundle_trijoinrecdata (trijoin_rec_inv (trijoin_rec f)))
                    (unbundle_trijoinrecdata f).
Proof.
  snrapply Build_TriJoinRecPath'; cbn.
  - apply trijoin_rec_beta_join12.
  - apply trijoin_rec_beta_join13.
  - apply trijoin_rec_beta_join23.
  - intros a b c.
    unfold prism'.
    apply moveR_pM.
    nrapply trijoin_rec_beta_join123.
Defined.

(** We can upgrade this to an unprimed path. This says that [trijoin_rec_inv] is split surjective. *)
Definition trijoin_rec_beta {A B C P : Type} (f : TriJoinRecData A B C P)
  : TriJoinRecPath (trijoin_rec_inv (trijoin_rec f)) f
  := bundle_trijoinrecpath (trijoin_rec_beta' f).

(** * Next we show that [trijoin_rec_inv] is an injective map between 0-groupoids. *)

(** We begin with a general purpose lemma. *)
Definition triangle_ind {P : Type} (a : P)
  (Q : forall (b c : P) (ab : a = b) (ac : a = c) (bc : b = c) (abc : ab @ bc = ac), Type)
  (s : Q a a idpath idpath idpath idpath)
  : forall b c ab ac bc abc, Q b c ab ac bc abc.
Proof.
  intros.
  induction ab.
  induction bc.
  induction abc.
  apply s.
Defined.

(** This lemma handles the path algebra in the last goal of the next result. *)
Local Definition isinj_trijoin_rec_inv_helper {J P : Type} {f g : J -> P}
  {a b c : J} {ab : a = b} {ac : a = c} {bc : b = c} {abc : ab @ bc = ac}
  {H1 : f a = g a} {H2 : f b = g b} {H3 : f c = g c}
  {H12 : ap f ab @ H2 = H1 @ ap g ab}
  {H13 : ap f ac @ H3 = H1 @ ap g ac}
  {H23 : ap f bc @ H3 = H2 @ ap g bc}
  (H123 : prism (ap_triangle f abc) (ap_triangle g abc) H12 H13 H23)
  : (transport_pp (fun x => f x = g x) ab bc H1 @ ap (transport (fun x => f x = g x) bc)
       (transport_paths_FlFr' ab H1 H2 H12)) @ transport_paths_FlFr' bc H2 H3 H23
    = transport2 (fun x => f x = g x) abc H1 @ transport_paths_FlFr' ac H1 H3 H13.
Proof.
  revert b c ab ac bc abc H2 H3 H12 H13 H23 H123.
  nrapply triangle_ind; cbn.
  unfold ap_triangle, transport_paths_FlFr', transport; cbn -[concat_pp_p].
  generalize dependent (f a); intro fa; clear f.
  generalize dependent (g a); intro ga; clear g a.
  intros H1 H2 H3 H12 H13 H23.
  rewrite ap_idmap.
  revert H12; equiv_intro (equiv_1p_q1 (p:=H2) (q:=H1)) H12'; induction H12'.
  revert H13; equiv_intro (equiv_1p_q1 (p:=H3) (q:=H2)) H13'; induction H13'.
  induction H3.
  intro H123.
  unfold prism in H123.
  rewrite whiskerL_1p_1 in H123.
  cbn in *.
  rewrite ! concat_p1 in H123.
  induction H123.
  reflexivity.
Qed.

(** [trijoin_rec_inv] is essentially injective, as a map between 0-groupoids. *)
Definition isinj_trijoin_rec_inv {A B C P : Type} {f g : TriJoin A B C -> P}
  (h : TriJoinRecPath (trijoin_rec_inv f) (trijoin_rec_inv g))
  : f == g.
Proof.
  snrapply trijoin_ind.
  1: apply (h1 h).
  1: apply (h2 h).
  1: apply (h3 h).
  1, 2, 3: intros; nrapply transport_paths_FlFr'.
  1: apply (h12 h).
  1: apply (h13 h).
  1: apply (h23 h).
  intros a b c; cbn beta.
  apply isinj_trijoin_rec_inv_helper.
  exact (h123 h a b c).
Defined.

(** * We now introduce several lemmas and tactics that will dispense with some routine goals. The idea is that a generic triangle can be assumed to be trivial on the first vertex, and a generic prism can be assumed to be the identity on the domain. In order to apply the [triangle_ind] and [prism_ind] lemmas that make this precise, we need to generalize various terms in the goal. *)

(** This destructs a seven component term [f], tries to generalize each piece evaluated appropriately, and clears all pieces.  If called with [a], [b] and [c] all valid terms, we expect all seven components to be generalized.  But one can also call it with one of [a], [b] and [c] a dummy value (e.g. [_X_]) that causes four of the [generalize] tactics to fail.  In this case, four components will be simply cleared, and three will be generalized and cleared, so this applies when the goal only depends on three of the seven components. *)
Ltac generalize_some f a b c :=
  let f1 := fresh in let f2 := fresh in let f3 := fresh in
  let f12 := fresh in let f13 := fresh in let f23 := fresh in
  let f123 := fresh in
  destruct f as [f1 f2 f3 f12 f13 f23 f123]; cbn;
  try generalize (f123 a b c); clear f123;
  try generalize (f23 b c); clear f23;
  try generalize (f13 a c); clear f13;
  try generalize (f12 a b); clear f12;
  try generalize (f3 c); clear f3;
  try generalize (f2 b); clear f2;
  try generalize (f1 a); clear f1.
  (* No easy way to skip the "last" one, since we don't know which will be the last to be generalized. *)

(** Use this with [f : TriJoinRecData A B C P], [a : A], [b : B], [c : C]. *)
Ltac triangle_ind f a b c :=
  generalize_some f a b c;
  intro f; (* [generalize_some] goes one step too far, so intro the last variable. *)
  apply triangle_ind.

(** Use this with [f : TriJoinRecData A B C P]. Two of the arguments [a], [b] and [c] should be elements of [A], [B] and [C], respectively, and the third should be a dummy value (e.g. [_X_]) that causes the generalize tactic to fail.  It applies to goals that only depend on the components of [f] involving just two of [A], [B] and [C]. *)
Ltac triangle_ind_two f a b c :=
  generalize_some f a b c;
  intro f; (* [generalize_some] goes one step too far, so intro the last variable. *)
  apply paths_ind.

(** The prism analog of the function [triangle_ind] from earlier in the file. To prove something about all prisms, it's enough to prove it for the "identity" prism.  Note that we don't specialize to a prism concentrated on a single vertex, since sometimes we have to deal with a composite of two prisms. *)
Definition prism_ind {P : Type} (a b c : P) (ab : a = b) (ac : a = c) (bc : b = c) (abc : ab @ bc = ac)
  (Q : forall (a' b' c' : P) (ab' : a' = b') (ac' : a' = c') (bc' : b' = c') (abc' : ab' @ bc' = ac')
         (k1 : a = a') (k2 : b = b') (k3 : c = c')
         (k12 : ab @ k2 = k1 @ ab') (k13 : ac @ k3 = k1 @ ac') (k23 : bc @ k3 = k2 @ bc')
         (k123 : prism abc abc' k12 k13 k23), Type)
  (s : Q a b c ab ac bc abc idpath idpath idpath (equiv_p1_1q idpath) (equiv_p1_1q idpath) (equiv_p1_1q idpath) (prism_id abc))
  : forall a' b' c' ab' ac' bc' abc' k1 k2 k3 k12 k13 k23 k123, Q a' b' c' ab' ac' bc' abc' k1 k2 k3 k12 k13 k23 k123.
Proof.
  intros.
  induction k1, k2, k3.
  revert k123.
  revert k12; equiv_intro (equiv_p1_1q (p:=ab) (q:=ab')) k12'; induction k12'.
  revert k13; equiv_intro (equiv_p1_1q (p:=ac) (q:=ac')) k13'; induction k13'.
  revert k23; equiv_intro (equiv_p1_1q (p:=bc) (q:=bc')) k23'; induction k23'.
  induction ab, bc, abc; simpl in *.
  unfold prism; simpl.
  equiv_intro (equiv_concat_r (concat_1p (whiskerL 1 abc') @ whiskerL_1p_1 abc')^ idpath) k123'.
  induction k123'.
  simpl.
  exact s.
Defined.

(** Use this with [f g : TriJoinRecData A B C P], [h : TriJoinRecPath f g] (so [g] is the *co*domain of [h]), [a : A], [b : B], [c : C]. *)
Ltac prism_ind g h a b c :=
  generalize_some h a b c;
  generalize_some g a b c;
  apply prism_ind.

(** Use this with [f g : TriJoinRecData A B C P], [h : TriJoinRecPath f g] (so [g] is the *co*domain of [h]).  Two of the arguments [a], [b] and [c] should be elements of [A], [B] and [C], respectively, and the third should be a dummy value (e.g. [_X_]) that causes the generalize tactic to fail.  It applies to goals that only depend on the components of [g] and [h] involving just two of [A], [B] and [C]. So it is dealing with one square face of the prism. *)
Ltac prism_ind_two g h a b c :=
  generalize_some h a b c;
  generalize_some g a b c;
  apply square_ind. (* From Join/Core.v *)

(** * Here we start using the WildCat library to organize things. *)

(** We begin by showing that [TriJoinRecData A B C P] is a 0-groupoid, one piece at a time. *)
Global Instance isgraph_trijoinrecdata (A B C P : Type) : IsGraph (TriJoinRecData A B C P)
  := {| Hom := TriJoinRecPath |}.

Global Instance is01cat_trijoinrecdata (A B C P : Type) : Is01Cat (TriJoinRecData A B C P).
Proof.
  apply Build_Is01Cat.
  - intro f.
    bundle_trijoinrecpath.
    1, 2, 3: reflexivity.
    intros a b c; cbn beta.
    (* Can finish with:  [by triangle_ind f a b c.] *)
    unfold prism'.
    cbn.
    apply concat_p1_1p.
  - intros f1 f2 f3 k2 k1.
    snrapply Build_TriJoinRecPath; intros; cbn beta.
    + exact (h1 k1 a @ h1 k2 a).
    + exact (h2 k1 b @ h2 k2 b).
    + exact (h3 k1 c @ h3 k2 c).
    + (* Some simple path algebra works as well. *)
      prism_ind_two f3 k2 a b _X_.
      prism_ind_two f2 k1 a b _X_.
      by triangle_ind_two f1 a b _X_.
    + prism_ind_two f3 k2 a _X_ c.
      prism_ind_two f2 k1 a _X_ c.
      by triangle_ind_two f1 a _X_ c.
    + prism_ind_two f3 k2 _X_ b c.
      prism_ind_two f2 k1 _X_ b c.
      by triangle_ind_two f1 _X_ b c.
    + cbn beta. prism_ind f3 k2 a b c.
      prism_ind f2 k1 a b c.
      by triangle_ind f1 a b c.
Defined.

Global Instance is0gpd_trijoinrecdata (A B C P : Type) : Is0Gpd (TriJoinRecData A B C P).
Proof.
  apply Build_Is0Gpd.
  intros f g h.
  snrapply Build_TriJoinRecPath; intros; cbn beta.
  + exact (h1 h a)^.
  + exact (h2 h b)^.
  + exact (h3 h c)^.
  + (* Some simple path algebra works as well. *)
    prism_ind_two g h a b _X_.
    by triangle_ind_two f a b _X_.
  + prism_ind_two g h a _X_ c.
    by triangle_ind_two f a _X_ c.
  + prism_ind_two g h _X_ b c.
    by triangle_ind_two f _X_ b c.
  + prism_ind g h a b c.
    by triangle_ind f a b c.
Defined.

Definition trijoinrecdata_0gpd (A B C P : Type) : ZeroGpd
  := Build_ZeroGpd (TriJoinRecData A B C P) _ _ _.

(** * Next we show that [trijoinrecdata_0gpd A B C] is a 1-functor from [Type] to [ZeroGpd]. *)

(** It's a 1-functor that lands in [ZeroGpd], and the morphisms of [ZeroGpd] are 0-functors, so it's easy to get confused about the levels. *)

(** First we need to show that the induced map is a morphism in [ZeroGpd], i.e. that it is a 0-functor. *)
Global Instance is0functor_trijoinrecdata_fun {A B C P Q : Type} (g : P -> Q)
  : Is0Functor (@trijoinrecdata_fun A B C P Q g).
Proof.
  apply Build_Is0Functor.
  intros f1 f2 h.
  snrapply Build_TriJoinRecPath; intros; cbn.
  1, 2, 3: apply (ap g).
  1: apply (h1 h).
  1: apply (h2 h).
  1: apply (h3 h).
  1, 2, 3: refine ((ap_pp g _ _)^ @ _ @ ap_pp g _ _); apply (ap (ap g)).
  1: apply (h12 h). (* Or: prism_ind_12 f2 h a b. triangle_ind_12 f1 a b. reflexivity. *)
  1: apply (h13 h).
  1: apply (h23 h).
  prism_ind f2 h a b c.
  triangle_ind f1 a b c; cbn.
  reflexivity.
Defined.

(** [trijoinrecdata_0gpd A B C] is a 0-functor from [Type] to [ZeroGpd] (one level up). *)
Global Instance is0functor_trijoinrecdata_0gpd (A B C : Type) : Is0Functor (trijoinrecdata_0gpd A B C).
Proof.
  apply Build_Is0Functor.
  intros P Q g.
  snrapply Build_Morphism_0Gpd.
  - exact (trijoinrecdata_fun g).
  - apply is0functor_trijoinrecdata_fun.
Defined.

(** [trijoinrecdata_0gpd A B C] is a 1-functor from [Type] to [ZeroGpd]. *)
Global Instance is1functor_trijoinrecdata_0gpd (A B C : Type) : Is1Functor (trijoinrecdata_0gpd A B C).
Proof.
  apply Build_Is1Functor.
  (* If [g1 g2 : P -> Q] are homotopic, then the induced maps are homotopic: *)
  - intros P Q g1 g2 h f; cbn in *.
    snrapply Build_TriJoinRecPath; intros; cbn.
    1, 2, 3: apply h.
    1, 2, 3: apply concat_Ap.
    triangle_ind f a b c; cbn.
    by induction (h f).
  (* The identity map [P -> P] is sent to a map homotopic to the identity. *)
  - intros P f; cbn.
    bundle_trijoinrecpath; intros; cbn.
    1, 2, 3: apply ap_idmap.
    by triangle_ind f a b c.
  (* It respects composition. *)
  - intros P Q R g1 g2 f; cbn.
    bundle_trijoinrecpath; intros; cbn.
    1, 2, 3: apply ap_compose.
    by triangle_ind f a b c.
Defined.

Definition trijoinrecdata_0gpd_fun (A B C : Type) : Fun11 Type ZeroGpd
  := Build_Fun11 _ _ (trijoinrecdata_0gpd A B C).

(** By the Yoneda lemma, it follows from [TriJoinRecData] being a 1-functor that given [TriJoinRecData] in [J], we get a map [(J -> P) $-> (TriJoinRecData A B C P)] of 0-groupoids which is natural in [P]. Below we will specialize to the case where [J] is [TriJoin A B C] with the canonical [TriJoinRecData]. *)
Definition trijoin_nattrans_recdata {A B C J : Type} (f : TriJoinRecData A B C J)
  : NatTrans (opyon_0gpd J) (trijoinrecdata_0gpd_fun A B C).
Proof.
  snrapply Build_NatTrans.
  - rapply opyoneda_0gpd; exact f.
  - exact _.
Defined.  

(** Thus we get a map [(TriJoin A B C -> P) $-> (TriJoinRecData A B C P)] of 0-groupoids, natural in [P]. The underlying map is [trijoin_rec_inv A B C P]. *)
Definition trijoin_rec_inv_nattrans (A B C : Type)
  : NatTrans (opyon_0gpd (TriJoin A B C)) (trijoinrecdata_0gpd_fun A B C)
  := trijoin_nattrans_recdata (trijoinrecdata_trijoin A B C).

(** This natural transformation is in fact a natural equivalence of 0-groupoids. *)
Definition trijoin_rec_inv_natequiv (A B C : Type)
  : NatEquiv (opyon_0gpd (TriJoin A B C)) (trijoinrecdata_0gpd_fun A B C).
Proof.
  snrapply Build_NatEquiv'.
  1: apply trijoin_rec_inv_nattrans.
  intro P.
  apply isequiv_0gpd_issurjinj.
  apply Build_IsSurjInj.
  - intros f; cbn in f.
    exists (trijoin_rec f).
    apply trijoin_rec_beta.
  - exact (@isinj_trijoin_rec_inv A B C P).
Defined.

(** It will be handy to name the inverse natural equivalence. *)
Definition trijoin_rec_natequiv (A B C : Type)
  := natequiv_inverse _ _ (trijoin_rec_inv_natequiv A B C).

(** [trijoin_rec_natequiv A B C P] is an equivalence of 0-groupoids whose underlying function is definitionally [trijoin_rec]. *)
Local Definition trijoin_rec_natequiv_check (A B C P : Type)
  : equiv_fun_0gpd (trijoin_rec_natequiv A B C P) = @trijoin_rec A B C P
  := idpath.

(** It follows that [trijoin_rec A B C P] is a 0-functor. *)
Global Instance is0functor_trijoin_rec (A B C P : Type) : Is0Functor (@trijoin_rec A B C P).
Proof.
  change (Is0Functor (equiv_fun_0gpd (trijoin_rec_natequiv A B C P))).
  exact _.
Defined.

(** And that [trijoin_rec A B C] is natural.   The [$==] in the statement is just [==], but we use WildCat notation so that we can invert and compose these with WildCat notation. *)
Definition trijoin_rec_nat (A B C : Type) {P Q : Type} (g : P -> Q)
  (f : TriJoinRecData A B C P)
  : trijoin_rec (trijoinrecdata_fun g f) $== g o trijoin_rec f.
Proof.
  exact (isnat (trijoin_rec_natequiv A B C) g f).
Defined.
