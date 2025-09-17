import os
import re

def fix_with_opacity_safe(file_path):
    """Safely fix withOpacity calls in a Dart file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # More precise regex that captures the complete value
        pattern = r'\.withOpacity\(([0-9]+\.?[0-9]*)\)'
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
    """Fix withOpacity in specific files"""
    files_to_fix = [
        'lib/device_music_page.dart',
        'lib/device_music_page_new.dart'
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_with_opacity_safe(file_path):
                fixed_count += 1
        else:
            print(f"File not found: {file_path}")
    
    print(f"Fixed withOpacity in {fixed_count} files")

if __name__ == "__main__":
    main()
