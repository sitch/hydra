package hydra.core;

/**
 * Any of a fixed set of literal types, also called atomic types, base types, primitive types, or type constants
 */
public abstract class LiteralType {
  private LiteralType() {}
  
  public abstract <R> R accept(Visitor<R> visitor) ;
  
  /**
   * An interface for applying a function to a LiteralType according to its variant (subclass)
   */
  public interface Visitor<R> {
    R visit(Binary instance) ;
    
    R visit(BooleanEsc instance) ;
    
    R visit(FloatEsc instance) ;
    
    R visit(IntegerEsc instance) ;
    
    R visit(StringEsc instance) ;
  }
  
  /**
   * An interface for applying a function to a LiteralType according to its variant (subclass). If a visit() method for a
   * particular variant is not implemented, a default method is used instead.
   */
  public interface PartialVisitor<R> extends Visitor<R> {
    default R otherwise(LiteralType instance) {
      throw new IllegalStateException("Non-exhaustive patterns when matching: " + instance);
    }
    
    @Override
    default R visit(Binary instance) {
      return otherwise(instance);
    }
    
    @Override
    default R visit(BooleanEsc instance) {
      return otherwise(instance);
    }
    
    @Override
    default R visit(FloatEsc instance) {
      return otherwise(instance);
    }
    
    @Override
    default R visit(IntegerEsc instance) {
      return otherwise(instance);
    }
    
    @Override
    default R visit(StringEsc instance) {
      return otherwise(instance);
    }
  }
  
  public static final class Binary extends LiteralType {
    /**
     * Constructs an immutable Binary object
     */
    public Binary() {}
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof Binary)) {
          return false;
      }
      Binary o = (Binary) other;
      return true;
    }
    
    @Override
    public int hashCode() {
      return 0;
    }
  }
  
  public static final class BooleanEsc extends LiteralType {
    /**
     * Constructs an immutable BooleanEsc object
     */
    public BooleanEsc() {}
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof BooleanEsc)) {
          return false;
      }
      BooleanEsc o = (BooleanEsc) other;
      return true;
    }
    
    @Override
    public int hashCode() {
      return 0;
    }
  }
  
  public static final class FloatEsc extends LiteralType {
    public final hydra.core.FloatType floatEsc;
    
    /**
     * Constructs an immutable FloatEsc object
     */
    public FloatEsc(hydra.core.FloatType floatEsc) {
      this.floatEsc = floatEsc;
    }
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof FloatEsc)) {
          return false;
      }
      FloatEsc o = (FloatEsc) other;
      return floatEsc.equals(o.floatEsc);
    }
    
    @Override
    public int hashCode() {
      return 2 * floatEsc.hashCode();
    }
  }
  
  public static final class IntegerEsc extends LiteralType {
    public final hydra.core.IntegerType integer;
    
    /**
     * Constructs an immutable IntegerEsc object
     */
    public IntegerEsc(hydra.core.IntegerType integer) {
      this.integer = integer;
    }
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof IntegerEsc)) {
          return false;
      }
      IntegerEsc o = (IntegerEsc) other;
      return integer.equals(o.integer);
    }
    
    @Override
    public int hashCode() {
      return 2 * integer.hashCode();
    }
  }
  
  public static final class StringEsc extends LiteralType {
    /**
     * Constructs an immutable StringEsc object
     */
    public StringEsc() {}
    
    @Override
    public <R> R accept(Visitor<R> visitor) {
      return visitor.visit(this);
    }
    
    @Override
    public boolean equals(Object other) {
      if (!(other instanceof StringEsc)) {
          return false;
      }
      StringEsc o = (StringEsc) other;
      return true;
    }
    
    @Override
    public int hashCode() {
      return 0;
    }
  }
}
