AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides tooltips for global constants.
##
class Provider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    onChangeCursorPosition: (editor, newBufferPosition) ->
        @removeCallTip()

        invocationInfo = @service.getInvocationInfoAt(editor, newBufferPosition)

        return if not invocationInfo?

        callStack = invocationInfo.callStack

        method = null
        methodName = callStack.pop()

        return if not callStack

        if callStack.length > 0
            type = @service.parser.getResultingTypeFromCallStack(editor, invocationInfo.bufferPosition, callStack)

            method = @service.getClassMethod(type, methodName)

        else
            globalFunctions = @service.getGlobalFunctions()

            if methodName of globalFunctions
                method = globalFunctions[methodName]

        if method?
            callTipText = @getFunctionCallTip(method, invocationInfo.argumentIndex)

            @showCallTip(editor, newBufferPosition, callTipText)

    ###*
     * Builds the call tip for a PHP function or method.
     *
     * @param {array}       info                 Information about the function or method.
     * @param {number|null} activeArgumentNumber The number (starting from 0) of the argument that needs to be
     *                                           highlighted. Set to null to highlight nothing.
     *
     * @return {string}
    ###
    getFunctionCallTip: (info, activeArgumentNumber = null) ->
        return '(No parameters)' if info.parameters.length == 0

        body = ''

        isInOptionalList = false

        for param, index in info.parameters
            body += '['   if param.isOptional and not isInOptionalList
            body += ', '  if index != 0
            body += '<strong>' if activeArgumentNumber == index
            body += (param.type + ' ') if param.type
            body += '&'   if param.isReference
            body += '$' + param.name
            body += '...' if param.isVariadic
            body += '</strong>' if activeArgumentNumber == index
            body += ']'  if param.isOptional and index == (info.parameters.length - 1)

            isInOptionalList = param.isOptional

        return body
