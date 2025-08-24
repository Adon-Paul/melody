import os
import re

def fix_with_opacity_in_file(file_path):
    """Fix withOpacity calls in a Dart file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace .withOpacity(value) with .withValues(alpha: value)
        pattern = r'\.withOpacity\(([^)]+)\)'
        replacement = r'.withValues(alpha: \1)'
        new_content = re.sub(pattern, replacement, content)
        
        if content != new_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed withOpacity in: {file_path}")
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Fix withOpacity in all Dart files"""
    dart_files = []
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    fixed_count = 0
    for dart_file in dart_files:
        if fix_with_opacity_in_file(dart_file):
            fixed_count += 1
    
    print(f"Fixed withOpacity in {fixed_count} files")

if __name__ == "__main__":
    main()
