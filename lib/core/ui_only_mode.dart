/// UI/UX-only switch for the experimental bolaGpt1 branch.
///
/// This branch keeps the production screens and navigation intact while
/// preventing business data from being persisted between application runs.
/// Keep this enabled only on bolaGpt1; production branches must not import it.
class UiOnlyMode {
  UiOnlyMode._();

  static const bool enabled = true;
}
