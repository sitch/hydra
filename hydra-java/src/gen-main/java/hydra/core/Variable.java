package hydra.core;

/**
 * A symbol which stands in for a term
 */
public class Variable {
  public final String value;
  
  /**
   * Constructs an immutable Variable object
   */
  public Variable(String value) {
    this.value = value;
  }
  
  @Override
  public boolean equals(Object other) {
    if (!(other instanceof Variable)) {
        return false;
    }
    Variable o = (Variable) other;
    return value.equals(o.value);
  }
  
  @Override
  public int hashCode() {
    return 2 * value.hashCode();
  }
}
