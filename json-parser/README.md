# JSON parser

[RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259#section-7)

## Considerations

- Library will return an struct type called `JSONResult`
- `JSONResult` will contain a field `value` of union type `JSONType`
- `JSONType` may contain an `object`, an `array`, an `string`, a `boolean`, a
  `number` or `null`
- `number` values will be represented as `f64` or `i64`, depending on their syntax
- `string` values will be represented as `[]const u8`

## Author

[beto0607](https://github.com/beto0607)
