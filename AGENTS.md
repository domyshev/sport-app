# Project Instructions

- Work only inside current folder for this project. Never touch (read or write) any file in the file system outside this folder.
- Never modify `from_garmin_official_export` even you were asked about this in the chat
- For every user request in this project, append the request text to `docs/steps_human.md` as the next numbered step before completing the work, unless the user explicitly says not to update the steps. You you were asked "Don't do anything just say", you should still add user request to this file.
  All human request should be saved in this file.
- Use the existing `docs/steps_human.md` format for new steps: a fixed-width 16x8 (width * height) `text` block with `шаг N` inside the symbolic picture, followed by a separate `text` block containing the request.
- Keep user-facing project documentation in Russian when the user writes in Russian.
- Never do git commits yourself
- Always check that you will not create any data file with potentially-sensitive data as trainings history that will be commited to the git. 
  If you create such a file or folder you are required to add it to gitignore and say it in the chat!
