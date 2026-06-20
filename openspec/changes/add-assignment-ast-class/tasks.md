## 1. AST Implementation
- [x] 1.1 Add Assignment class to ast.dart extending Statement
- [x] 1.2 Add Assignment.toJson() and Assignment.fromJson() methods
- [x] 1.3 Update ConfigElement.fromJson() to handle Assignment type
- [x] 1.4 Add Assignment to visitor pattern support
- [x] 1.5 Update Config.statements to include Assignment objects

## 2. Grammar Implementation
- [x] 2.1 Remove current assignStmt() parser that creates Command objects
- [x] 2.2 Implement new assignStmt() parser using proposed grammar structure
- [x] 2.3 Add Assignment-specific parsing logic: LHS WS* AssignOp WS* RhsList
- [x] 2.4 Update statement() parser to include assignStmt() as alternative
- [x] 2.5 Ensure position tracking works for Assignment objects

## 3. Parser Integration
- [x] 3.1 Update main parser to handle Assignment objects in statements
- [x] 3.2 Verify assignment parsing works in both root and block contexts
- [x] 3.3 Test assignment parsing with source position tracking
- [x] 3.4 Ensure assignments work with line continuation support

## 4. Testing
- [x] 4.1 Update existing assignment tests to expect Assignment objects
- [x] 4.2 Add comprehensive Assignment class tests (equals, plus-equals)
- [x] 4.3 Test dotted identifiers in assignments (e.g., bar.colors.focused)
- [x] 4.4 Test multiple values in RhsList assignments
- [x] 4.5 Test assignment JSON serialization/deserialization
- [x] 4.6 Verify all existing tests still pass

## 5. Documentation Updates
- [x] 5.1 Update README.md examples to use Assignment API
- [x] 5.2 Update CHANGELOG.md with breaking change information
- [x] 5.3 Add migration guide for Assignment API changes
- [x] 5.4 Update example files to demonstrate Assignment usage

## 6. Backward Compatibility
- [ ] 6.1 Consider adding deprecation warnings for old assignment detection patterns *(Not required for 2.0.0 breaking release)*
- [x] 6.2 Update visitor pattern handlers to work with Assignment objects
- [x] 6.3 Ensure examples directory code works with new Assignment API
