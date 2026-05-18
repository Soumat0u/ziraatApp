import os
import re

lib_dir = r"c:\Users\PC\Desktop\Projeler\ziraatApp\mobile\lib"

replacements = {
    r"AppTheme\.backgroundGray": r"Theme.of(context).scaffoldBackgroundColor",
    r"AppTheme\.backgroundLight": r"Theme.of(context).cardColor",
    r"AppTheme\.textPrimary": r"Theme.of(context).colorScheme.onSurface",
    r"AppTheme\.textSecondary": r"Theme.of(context).colorScheme.onSurfaceVariant"
}

modified_files = 0

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            original_content = content
            for old, new in replacements.items():
                content = re.sub(old, new, content)
                
            if content != original_content:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)
                modified_files += 1
                print(f"Updated: {path}")

print(f"Total files updated: {modified_files}")
