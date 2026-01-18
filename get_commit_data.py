import requests
import re
import time
import os

TOKEN_FILE = 'api_git_token.txt'
GITHUB_TOKEN = None

if os.path.exists(TOKEN_FILE):
    with open(TOKEN_FILE, 'r') as f:
        GITHUB_TOKEN = f.read().strip() 

HEADERS = {}
if GITHUB_TOKEN:
    print(f"Найден токен в файле '{TOKEN_FILE}'.")
    HEADERS['Authorization'] = f'token {GITHUB_TOKEN}'
else:
    print(f"Файл '{TOKEN_FILE}' не найден. Используются неаутентифицированные запросы с лимитом 60/час.")

REPOS_FILE = 'repos.txt'
OUTPUT_FILE = 'commit_emails.txt'
API_URL_TEMPLATE = 'https://api.github.com/repos/{owner}/{repo}/commits'

def parse_github_url(url):
    match = re.search(r"github\.com/([\w\-\.]+)/([\w\-\.]+)", url)
    if match:
        return match.groups()
    return None, None

def get_emails_from_repo(owner, repo):
    emails = []
    page = 1
    while True:
        try:
            print(f"  - Запрос страницы {page} для {owner}/{repo}...")
            response = requests.get(
                API_URL_TEMPLATE.format(owner=owner, repo=repo),
                params={'per_page': 100, 'page': page},
                headers=HEADERS
            )
            
            if response.status_code == 403:
                remaining = int(response.headers.get('X-RateLimit-Remaining', 0))
                if remaining == 0:
                    print("Достигнут лимит запросов к API GitHub")
                    break
            
            response.raise_for_status()
            
            data = response.json()
            if not data:
                break
            
            for commit_data in data:
                try:
                    email = commit_data['commit']['author']['email']
                    emails.append(email)
                except (KeyError, TypeError):
                    continue
            
            page += 1
            time.sleep(0.5)

        except requests.exceptions.RequestException as e:
            print(f"Ошибка при запросе к API для {owner}/{repo}: {e}")
            break
            
    return emails

if __name__ == '__main__':
    all_emails = []
    print("--- Начало сбора данных коммитов ---")
    
    with open(REPOS_FILE, 'r') as f:
        for line in f:
            repo_url = line.strip()
            if not repo_url:
                continue
            
            owner, repo_name = parse_github_url(repo_url)
            
            if owner and repo_name:
                print(f"Обработка репозитория: {owner}/{repo_name}")
                emails = get_emails_from_repo(owner, repo_name)
                all_emails.extend(emails)
                print(f"Найдено {len(emails)} коммитов. Всего собрано: {len(all_emails)}.")
            else:
                print(f"Не удалось распознать URL: {repo_url}")

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        for email in all_emails:
            f.write(email + '\n')
            
    print(f"--- Все email'ы сохранены в {OUTPUT_FILE} ---")