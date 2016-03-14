# typecheck a value

types = require('shift-spec').default

flatten = (types) ->
  allTypes = []

  for type in types
    if type.typeName is 'Union'
      allTypes = allTypes.concat flatten type.arguments
    else
      allTypes.push type.typeName

  allTypes

checkUnion = (types, value, str) ->
  unless types?
    throw new Error "Union must provide nested types"

  for type in types
    try
      typecheck type, value
      return

  ts = flatten(types).join ', '
  throw new Error "Expected one of [#{ts}], got #{str}"

checkEnum = (options, value, str) ->
  unless options?
    throw new Error "Enum must provide value options"

  for option in options
    return if value is option

  os = options.join ', '
  throw new Error "Expected value to be in [#{os}], got #{str}"

checkList = (type, value, str) ->
  unless type?
    throw new Error "List must provide element type"

  unless Array.isArray value
    throw new Error "Expected a List, got #{str}"

  for element in value
    typecheck type, element

checkNode = (name, type, value, str, requireSomething=yes) ->
  unless type?.fields?
    throw new Error "Node type must provide fields (??)"

  unless typeof value is 'object' or !value?
    throw new Error "Expected a #{name}, got #{str}"

  if value?.type? and value.type isnt name
    throw new Error "Expected a #{name}, got a #{value.type}"

  for field in type.fields when field.name isnt 'type'
    if requireSomething and not value?
      throw new Error "Expected something (??)"

    try
      typecheck field.type, value?[field.name]
    catch e
      e.message += ' in property "' + field.name + '"'
      throw e

module.exports = typecheck = (type, value, isRoot=no) ->
  str = JSON.stringify value

  switch type.typeName

    # primitive types

    when 'String'
      if not value? or value.toString() isnt value
        throw new Error "Expected a string, got #{str}"

    when 'Number'
      if +value isnt value
        throw new Error "Expected a number, got #{str}"

    when 'Boolean'
      if !!value isnt value
        throw new Error "Expected a boolean, got #{str}"

    # complex types

    when 'Maybe'
      unless type.argument?
        throw new Error "Maybe must provide child type"

      if value?
        typecheck type.argument, value

    when 'Union'
      checkUnion type.arguments, value, str

    when 'Enum'
      checkEnum type.values, value, str

    when 'List'
      checkList type.argument, value, str

    # meta-error

    when undefined
      strType = JSON.stringify type
      throw new Error "Invalid type supplied: #{strType}"

    # AST node

    else
      if type.typeName not of types
        throw new Error 'Unknown type "' + type.typeName + '"'

      checkNode type.typeName, types[type.typeName], value, str, not isRoot

  undefined
