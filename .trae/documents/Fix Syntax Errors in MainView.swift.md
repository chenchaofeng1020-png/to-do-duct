I have identified the cause of the build failure.

**Root Cause:**
In `MainView.swift`, there is an extra closing brace `}` at **line 360**.
This brace prematurely closes the `body` property of `TodoHomeView`. As a result, the subsequent modifiers (like `.overlay`, `.sheet`, etc.) are treated as being at the `struct` level, causing the "Expected declaration" error.
The Python script analysis confirmed an "Extra }" at line 469, which is the cascading result of this premature closure.

The error you see in the screenshot at line 1058 (`TodoItemRowNew`) is likely a cascading error caused by the parser confusion from the earlier syntax error in `TodoHomeView`, or a similar brace mismatch if the file has multiple issues. I will apply a fix for the clear error in `TodoHomeView` and also refactor the code in `TodoItemRowNew` to be safer.

**Plan:**

1. **Edit** **`To-Do Duck/MainView.swift`**:

   * **Remove the extra** **`}`** **at line 360** inside `TodoHomeView`. This will correctly include the following modifiers (`.overlay`, `.sheet`, etc.) inside the `body`.

   * **Refactor** **`TodoItemRowNew`** **(around line 1046)**: Change the `if let idx = item.chainIndex, idx >= 2` syntax to a nested `if let` and `if` structure. This is safer for the compiler and ensures the "Expected declaration" error at line 1058 is resolved if it was due to parser ambiguity.

**Verification:**

* After the edit, I will run the brace checking script again to ensure all braces are balanced.

* (Since I cannot run the Xcode build directly, checking braces is the best verification).

