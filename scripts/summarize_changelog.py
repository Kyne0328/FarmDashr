import os
import sys
import google.generativeai as genai

def summarize_changelog(raw_changelog):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set.")
        sys.exit(1)

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-3-flash')

    prompt = f"""
    The following is a list of commit messages for a mobile app FarmDashR (Flutter). 
    Please summarize them into a professional and concise changelog.
    Categorize the changes into groups like "Features", "Improvements", "Bug Fixes", and "Chores/Internal".
    Make it user-friendly for a release note.
    
    Commit Messages:
    {raw_changelog}
    
    Summarized Changelog:
    """

    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        return raw_changelog

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python summarize_changelog.py <path_to_raw_changelog>")
        sys.exit(1)
        
    changelog_path = sys.argv[1]
    if not os.path.exists(changelog_path):
        print(f"Error: File {changelog_path} not found.")
        sys.exit(1)
        
    with open(changelog_path, 'r', encoding='utf-8') as f:
        raw_content = f.read()
        
    summarized = summarize_changelog(raw_content)
    print(summarized)
    
    # Also write to a file for GitHub Actions to use
    with open("summarized_changelog.md", "w", encoding='utf-8') as f:
        f.write(summarized)
