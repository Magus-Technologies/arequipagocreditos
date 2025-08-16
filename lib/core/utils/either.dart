/// Represents a value that can be either a failure (Left) or a success (Right)
/// This is commonly used for error handling in functional programming
class Either<L, R> {
  final L? _left;
  final R? _right;
  
  Either.left(L left) : 
    assert(left != null, 'Left value cannot be null'),
    _left = left, 
    _right = null;
    
  Either.right(R right) : 
    _left = null, 
    _right = right;
    
  /// Special constructor for void success results
  static Either<L, void> rightVoid<L>() => Either<L, void>.right(null);
  
  bool get isLeft => _left != null;
  bool get isRight => _left == null; // Si no es left, entonces es right
  
  /// Factory constructors for safe creation
  static Either<L, R> fromNullable<L, R>(R? value, L defaultLeft) {
    if (value != null) {
      return Either.right(value);
    }
    return Either.left(defaultLeft);
  }
  
  static Either<String, R> tryCreate<R>(R Function() creator) {
    try {
      final result = creator();
      if (result != null) {
        return Either.right(result);
      }
      return Either.left('Result is null');
    } catch (e) {
      return Either.left(e.toString());
    }
  }
  
  L get left {
    if (!isLeft) throw StateError('Either is Right, cannot access left value');
    return _left!;
  }
  
  R get right {
    if (!isRight) throw StateError('Either is Left, cannot access right value');
    return _right as R;
  }
  
  /// Transform the Either by applying the appropriate function
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    if (isLeft) {
      if (_left == null) {
        throw StateError('Left value is null');
      }
      return onLeft(_left as L);
    } else {
      return onRight(_right as R);
    }
  }
  
  /// Map the right value if present
  Either<L, T> map<T>(T Function(R) f) {
    if (isRight) {
      return Either.right(f(_right as R));
    } else {
      if (_left == null) {
        throw StateError('Left value is null');
      }
      return Either.left(_left as L);
    }
  }
  
  /// FlatMap for chaining operations
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f) {
    if (isRight) {
      return f(_right as R);
    } else {
      if (_left == null) {
        throw StateError('Left value is null');
      }
      return Either.left(_left as L);
    }
  }
}
