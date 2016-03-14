# better checking on shift ast construction

ast = require 'shift-ast'
spec = require('shift-spec').default
typecheck = require './typecheck'

wrapConstructor = (name, constructor) ->
  unless name of spec
    throw new Error "Unknown AST node type #{name} (??)"

  typeSpec = spec[name]

  (props) ->
    typecheck typeSpec, props, yes

    new constructor props

constructors = {}

for name, constructor of ast when ast.hasOwnProperty name
  constructors[name] = wrapConstructor name, constructor

module.exports = constructors
