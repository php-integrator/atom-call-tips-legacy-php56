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
            try
                type = @service.parser.getResultingTypeFromCallStack(editor, invocationInfo.bufferPosition, callStack)

            catch error
                return # Can happen when a class type is used that doesn't exist (i.e. an use statement is missing).

            return if not type

            @service.getClassInfo(type, true).then (classInfo) =>
                if methodName of classInfo.methods
                    callTipText = @getFunctionCallTip(classInfo.methods[methodName], invocationInfo.argumentIndex)

                    @showCallTip(editor, newBufferPosition, callTipText)

        else
            @service.getGlobalFunctions(true).then (globalFunctions) =>
                if methodName of globalFunctions
                    callTipText = @getFunctionCallTip(globalFunctions[methodName], invocationInfo.argumentIndex)

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
            isCurrentArgument = false

            if activeArgumentNumber == index
                isCurrentArgument = true

            else if activeArgumentNumber > index and param.isVariadic
                isCurrentArgument = true

            body += '['   if param.isOptional and not isInOptionalList
            body += ', '  if index != 0
            body += '<strong>' if isCurrentArgument
            body += (param.type + ' ') if param.type
            body += '&'   if param.isReference
            body += '$' + param.name
            body += '...' if param.isVariadic
            body += '</strong>' if isCurrentArgument
            body += ']'  if param.isOptional and index == (info.parameters.length - 1)

            isInOptionalList = param.isOptional

        return body
