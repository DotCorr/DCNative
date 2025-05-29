import UIKit
import dcflight

class DCFTextInputComponent: NSObject, DCFComponent, UITextFieldDelegate, UITextViewDelegate {
    private static let sharedInstance = DCFTextInputComponent()
    private static var textInputEventHandlers = [UIView: (String, [String], (String, String, [String: Any]) -> Void)]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        let isMultiline = props["multiline"] as? Bool ?? false
        
        let inputView: UIView
        if isMultiline {
            let textView = UITextView()
            textView.font = UIFont.systemFont(ofSize: 16)
            textView.layer.borderWidth = 1.0
            textView.layer.borderColor = UIColor.systemGray4.cgColor
            textView.layer.cornerRadius = 8.0
            textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            textView.delegate = DCFTextInputComponent.sharedInstance
            inputView = textView
        } else {
            let textField = UITextField()
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.borderStyle = .roundedRect
            textField.delegate = DCFTextInputComponent.sharedInstance
            inputView = textField
        }
        
        // Apply initial properties
        updateView(inputView, withProps: props)
        
        return inputView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        if let textField = view as? UITextField {
            return updateTextField(textField, withProps: props)
        } else if let textView = view as? UITextView {
            return updateTextView(textView, withProps: props)
        }
        return false
    }
    
    private func updateTextField(_ textField: UITextField, withProps props: [String: Any]) -> Bool {
        // Update text value
        if let value = props["value"] as? String {
            textField.text = value
        }
        
        // Update placeholder
        if let placeholder = props["placeholder"] as? String {
            textField.placeholder = placeholder
        }
        
        // Update placeholder color
        if let placeholderColor = props["placeholderTextColor"] as? String {
            textField.attributedPlaceholder = NSAttributedString(
                string: textField.placeholder ?? "",
                attributes: [NSAttributedString.Key.foregroundColor: ColorUtilities.color(fromHexString: placeholderColor)]
            )
        }
        
        // Update keyboard type
        if let keyboardType = props["keyboardType"] as? String {
            textField.keyboardType = mapKeyboardType(keyboardType)
        }
        
        // Update return key type
        if let returnKeyType = props["returnKeyType"] as? String {
            textField.returnKeyType = mapReturnKeyType(returnKeyType)
        }
        
        // Update auto-capitalization
        if let autoCapitalization = props["autoCapitalization"] as? String {
            textField.autocapitalizationType = mapAutoCapitalizationType(autoCapitalization)
        }
        
        // Update secure text entry
        if let secureTextEntry = props["secureTextEntry"] as? Bool {
            textField.isSecureTextEntry = secureTextEntry
        }
        
        // Update auto-correction
        if let autoCorrect = props["autoCorrect"] as? Bool {
            textField.autocorrectionType = autoCorrect ? .yes : .no
        }
        
        // Update editable state
        if let editable = props["editable"] as? Bool {
            textField.isEnabled = editable
        }
         // Update max length
        if let maxLength = props["maxLength"] as? Int {
            // Store max length for delegate validation
            objc_setAssociatedObject(textField, UnsafeRawPointer(bitPattern: "maxLength".hashValue)!, maxLength, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Apply StyleSheet properties for TextField
        textField.applyStyles(props: props)

        return true
    }
    
    private func updateTextView(_ textView: UITextView, withProps props: [String: Any]) -> Bool {
        // Update text value
        if let value = props["value"] as? String {
            textView.text = value
        }
        
        // Update keyboard type
        if let keyboardType = props["keyboardType"] as? String {
            textView.keyboardType = mapKeyboardType(keyboardType)
        }
        
        // Update return key type
        if let returnKeyType = props["returnKeyType"] as? String {
            textView.returnKeyType = mapReturnKeyType(returnKeyType)
        }
        
        // Update auto-capitalization
        if let autoCapitalization = props["autoCapitalization"] as? String {
            textView.autocapitalizationType = mapAutoCapitalizationType(autoCapitalization)
        }
        
        // Update auto-correction
        if let autoCorrect = props["autoCorrect"] as? Bool {
            textView.autocorrectionType = autoCorrect ? .yes : .no
        }
         // Update editable state
        if let editable = props["editable"] as? Bool {
            textView.isEditable = editable
        }
        
        // Apply StyleSheet properties for TextView
        textView.applyStyles(props: props)

        return true
    }
    
    // MARK: - Keyboard Type Mapping
    
    private func mapKeyboardType(_ type: String) -> UIKeyboardType {
        switch type {
        case "numbersAndPunctuation":
            return .numbersAndPunctuation
        case "numberPad":
            return .numberPad
        case "phonePad":
            return .phonePad
        case "namePhonePad":
            return .namePhonePad
        case "emailAddress":
            return .emailAddress
        case "decimalPad":
            return .decimalPad
        case "twitter":
            return .twitter
        case "webSearch":
            return .webSearch
        case "asciiCapableNumberPad":
            return .asciiCapableNumberPad
        default:
            return .default
        }
    }
    
    private func mapReturnKeyType(_ type: String) -> UIReturnKeyType {
        switch type {
        case "go":
            return .go
        case "google":
            return .google
        case "join":
            return .join
        case "next":
            return .next
        case "route":
            return .route
        case "search":
            return .search
        case "send":
            return .send
        case "yahoo":
            return .yahoo
        case "done":
            return .done
        case "emergencyCall":
            return .emergencyCall
        case "continue_":
            return .continue
        default:
            return .default
        }
    }
    
    private func mapAutoCapitalizationType(_ type: String) -> UITextAutocapitalizationType {
        switch type {
        case "words":
            return .words
        case "sentences":
            return .sentences
        case "allCharacters":
            return .allCharacters
        default:
            return .none
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Check max length
        if let maxLength = objc_getAssociatedObject(textField, UnsafeRawPointer(bitPattern: "maxLength".hashValue)!) as? Int {
            let currentText = textField.text ?? ""
            let newLength = currentText.count + string.count - range.length
            if newLength > maxLength {
                return false
            }
        }
        
        // Trigger onChangeText event using proper event system
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        triggerEventIfRegistered(textField, eventType: "onChangeText", eventData: ["text": newText])
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        triggerEventIfRegistered(textField, eventType: "onFocus", eventData: [:])
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        triggerEventIfRegistered(textField, eventType: "onBlur", eventData: [:])
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        triggerEventIfRegistered(textField, eventType: "onSubmitEditing", eventData: ["text": textField.text ?? ""])
        return true
    }
    
    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Trigger onChangeText event using proper event system
        let currentText = textView.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        triggerEventIfRegistered(textView, eventType: "onChangeText", eventData: ["text": newText])
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        triggerEventIfRegistered(textView, eventType: "onFocus", eventData: [:])
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        triggerEventIfRegistered(textView, eventType: "onBlur", eventData: [:])
    }
    
    // MARK: - Event Handling Implementation
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        print("📝 Adding TextInput event listeners to view \(viewId): \(eventTypes)")
        
        // Store event registration info
        DCFTextInputComponent.textInputEventHandlers[view] = (viewId, eventTypes, eventCallback)
        
        // Also store using associated objects as backup
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, 
                               eventCallback, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "viewId".hashValue)!, 
                               viewId, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
                               eventTypes,
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("✅ Successfully registered TextInput event handlers for view \(viewId)")
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        print("📝 Removing TextInput event listeners from view \(viewId): \(eventTypes)")
        
        // Remove from handlers dictionary
        DCFTextInputComponent.textInputEventHandlers.removeValue(forKey: view)
        
        // Clean up associated objects
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("✅ Removed TextInput event handlers for view \(viewId)")
    }
    
    // Trigger event if the view has been registered for that event type
    private func triggerEventIfRegistered(_ view: UIView, eventType: String, eventData: [String: Any]) {
        // Try handlers dictionary first
        if let (viewId, eventTypes, callback) = DCFTextInputComponent.textInputEventHandlers[view] {
            if eventTypes.contains(eventType) {
                print("✅ Triggering TextInput event: \(eventType) for view \(viewId)")
                callback(viewId, eventType, eventData)
                return
            }
        }
        
        // Fallback to associated objects
        guard let eventTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String],
              let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void,
              let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String else {
            print("📝 TextInput event not registered - no handlers found for \(eventType)")
            return
        }
        
        if eventTypes.contains(eventType) {
            print("✅ Triggering TextInput event (fallback): \(eventType) for view \(viewId)")
            callback(viewId, eventType, eventData)
        } else {
            print("📝 TextInput event \(eventType) not in registered types: \(eventTypes)")
        }
    }
}
