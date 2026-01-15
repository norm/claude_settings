Testing is how we can be confident our code works and will continue to work.
Implement code changes adding these steps as your TodoWrite list:

1.  **Clarify.** Read the task file for more information, do necessary code
    investigation, and ask any clarifying questions.

2.  **Ground.** Prove the tests pass.

3.  **Red.** Add or amend tests to assert the desired behaviour.
    Prove the test fails.

4.  **User Review.** We ensure the tests are correct, accurately cover the
    desired functionality, cover new edge cases, and are generally fit for
    purpose.

5.  **Green.** Update the code. Prove that the tests now pass.

6.  **Refactor.** Use a subagent to remove unnecessary code duplication,
    simplify, and make improvements to the performance of the code. Prove the
    tests still pass.

7.  **User review.** One last inspection.

8.  **Complete.** Tick off the completed tasks.

Tests should always be available at `make test`.
