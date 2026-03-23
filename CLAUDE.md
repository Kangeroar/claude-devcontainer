# Project

This is an Android Project creating an app that can control the camera on another paired Android device, controlling simple camera functions (zoom, focus etc) on camera A and trigger a photo capture on camera A from afar (~20 m) without internet.

## Tech Stack

Kotlin, CameraX API, Wi-Fi Direct (P2P), MediaCodec + MediaMuxer, Ktor (Sockets), Jetpack Compose,

# Agent Behaviour
- Work as a team of sub-agents, coordinated by the Tech-Lead.
- Generate code through tight learning loops, with test, code implementation and then reviews.
- Always write **tests first** (Plan + Do), then study results.
- Do not worry if the test code is written before the planned implementation and therefore does not compile - this isn't something to be avoided.
- Never jump ahead of what is needed — respect YAGNI.

# Codebase Rules
- Whenever you want to run commands that would normally use `./gradlew`, instead just run them with `gradle`. NEVER use `./gradlew` in this codebase since you're in a Docker environment.
- When running tests, run them with a timeout of 10 seconds. If a test timesout, assume that it is a hanging test that never finishes and fix it.

## After Each Step
- Ensure you've checked off any steps / sub-tasks that have been completed in any todo lists / checklists.
- Update relevant documentation including the `GEMINI.md` file, but don't keep logs of work in the `GEMINI.md` file, only useful information - instead, create a new markdown file in "docs/worklogs/" detailing the work done, with the markdown file name in the format of "YYYY-MM-DD-<number>-<task_name>.md" where <number> is the next unused integer number for worklogs on that date.
- Whenever a checklist has been completed, please update the diagrams in the `docs/` folder to reflect the changes in both the repository architecture and the user journey flow, using your "likec4" skill.
