#!/usr/bin/env python3
"""
Security Guard Hook - PreToolUse validation
"""
import sys
import json

def main():
    try:
        input_data = json.loads(sys.stdin.read())
        tool_name = input_data.get("tool", "")
        file_path = input_data.get("file", "") or input_data.get("filePath", "")

        if tool_name in ["Edit", "Write"]:
            sensitive_dirs = ["/etc/", "/usr/", "\Windows\\", "\Program Files\\"]
            for sensitive in sensitive_dirs:
                if sensitive.lower() in file_path.lower():
                    print(json.dumps({"status": "warning", "message": f"Writing to system directory: {file_path}"}), file=sys.stderr)
                    break

        print(json.dumps({"status": "allowed"}))
        sys.exit(0)
    except Exception as e:
        print(json.dumps({"status": "allowed", "error": str(e)}), file=sys.stderr)
        sys.exit(0)

if __name__ == "__main__":
    main()
