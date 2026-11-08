# Security Policy

## Supported Versions

This project is built for and tested against **Godot Engine 4.7**. Only the latest version running on the primary branch is actively maintained with security updates and bug fixes.

| Version | Supported          |
| :------ | :----------------- |
| `main` (Godot 4.7+) | :white_check_mark: |
| Older revisions    | :x:                |

---

## Security Architecture & Design Considerations

*Ultima VIII: Pagan — The 666 Procedural Realms* is designed as a **self-contained, standalone offline application** with strict security guarantees:

1. **Zero External Network Dependencies**:
   - The game runs entirely locally. It does not initiate outbound HTTP/HTTPS requests, phone-home telemetry, analytics, or external asset streaming.
2. **Deterministic Procedural Generation**:
   - All levels, 2D/3D sprites, wall textures, sound effects, and synth music are generated mathematically in memory within the GDScript virtual machine—eliminating risks associated with downloading untrusted remote content or binary assets.
3. **Restricted Local Storage (`user://`)**:
   - Save data, configuration files, and crash logs reside strictly inside Godot's designated user data directory (`user://` or `~/.local/share/godot/app_userdata/Ultima VIII- Pagan - The Sunken Sanctum/`).
   - The application does not read from or write to directories outside its sandboxed workspace.
4. **Strict GDScript Type Safety**:
   - The codebase strictly avoids dynamic code evaluation (`Expression.parse()` or unchecked `load()` / `ResourceLoader.load()` from external user strings) to mitigate injection or arbitrary code execution vulnerabilities.

---

## Reporting a Vulnerability

We appreciate responsible security research and coordinated disclosure. If you discover a security vulnerability or exploit within this project, please follow these guidelines:

### How to Report
- **Do not open a public GitHub issue** to report undisclosed security vulnerabilities.
- Please create a **Private Security Advisory** via GitHub by going to the repository's **Security** tab and clicking **Report a vulnerability**, or contact the repository maintainers directly.
- Include the following details in your report:
  - Description of the issue and potential impact.
  - Step-by-step reproduction instructions or proof-of-concept (PoC).
  - Operating system and Godot Engine version / build used.
  - Any suggested mitigations or patches.

### Response Timeline
- **Initial Acknowledgement**: Within 48 hours of report submission.
- **Triage & Assessment**: Within 5 business days, confirming whether the issue is reproducible and determining severity.
- **Fix & Public Advisory**: Once a patch has been validated, a coordinated release and advisory will be published.

Thank you for helping keep this open-source project and its community safe!
