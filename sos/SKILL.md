---
name: sos
description: User triggered skill to point in direction of help for common issues in the Knowledge Hub repo
---

1. If the user has not stated their problem or you cannot glean it from previous responses, use AskUserQuestion to understand the user's problem.
2. Use subagents to read all documentation in `docs/docs/`. If you do not find any information to help the user, proceed to step 3.
3. Direct the user to search slack for their error message or problem statement, as it's likely someone else has had the same issue and asked about it in the #core-tech-helpdesk channel. If the user is unable to find relevant information through searching, proceed to step 4.
4. Direct the user to ask their question in the #core-tech-helpdesk channel, where core tech team members can assist them. Provide best practices for asking for help in the channel, such as including relevant context, error messages, and steps already taken to troubleshoot.

