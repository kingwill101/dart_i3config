## 2.0.1

### Features
- fix parsing double quoted strings in sections when not using the assign operator
- Added topics metadata to package

## 2.0.0

### Breaking Changes
- Values are now automatically parsed into appropriate types (int, bool, double, string)
- Comments are now preserved and structured into CommentBlocks
- Fixed array handling in sections to properly group values under the same ArrayElement
- Changed Property value type from String to dynamic to support typed values

### Features
- Added type inference for configuration values
- Added structured comment preservation
- Improved array handling in sections
- Added JSON serialization support
## 1.1.1
- support properties with escaped curlies

## 1.0.1

- support section variables with longer names containing spaces
- add helpers for getting module name and types
## 1.0.0

- Initial version.
