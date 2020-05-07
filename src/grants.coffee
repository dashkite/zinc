import {tee} from "panda-garden"
import capability from "panda-capability"
import Confidential from "./confidential"

{SharedKey, PublicKey, Message, Envelope, encrypt, decrypt} = Confidential
{Directory, lookup, exercise} = capability Confidential

class Grants

  constructor: ({@directory, @keyPairs}) ->

  exercise: (request) -> Grants.exercise @, request

  add: (directory) -> Grants.add @, directory

  receive: (key, ciphertext) -> Grants.receive @, key, ciphertext

  @create: (object) -> new Grants object

  @toObject: (grants) -> @directory

  @fromObject: (object) -> new Grants object

  @add: tee (grants, directory) ->
    if grants.directory?
      for template, methods of directory
        for method, entry of methods
          grants.directory[template] ?= {}
          grants.directory[template][method] = entry
    else
      grants.directory = directory

  @receive: (grants, publicKey, ciphertext) ->
    sharedKey = SharedKey.create (PublicKey.from "base64", publicKey),
      grants.keyPairs.encryption.privateKey
    directory = Directory.from "bytes",
      (decrypt sharedKey, Envelope.from "base64", ciphertext).to "bytes"
    @add grants, directory

  @exercise: ({directory, keyPairs}, {path, parameters, method}) ->
    if directory? && (bundle = lookup directory, path, parameters)?
      if (_capability = bundle[method.toUpperCase()])?
        {grant, useKeyPairs} = _capability
        assertion = exercise keyPairs.signature,
          useKeyPairs, grant, url: parameters
        assertion.to "base64"

export default Grants