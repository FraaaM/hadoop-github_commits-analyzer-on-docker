# hadoop-github_commits-analyzer-on-docker
 
### Этот проект показывает вклад компаний в опен-сорс проекты по входящим коммитам. Программа парсит коммиты github и с помощью подхода map-reduce, встроенного в hadoop, эффективно обрабатывает входящий поток данных
### Для работы программы нужно ввести ссылки на интересующие репозитории в repos.txt, например:
```bash
https://github.com/apache/spark
https://github.com/apache/kafk
https://github.com/kubernetes/kubernetes
https://github.com/tensorflow/tensorflow
```
### Так же важно указать персональный github токен в api_git_token.txt

## Команды для запуска приложения
```bash
docker build -t hadoop-analyzer-py .
docker run -it --name hadoop-py-container -v "${PWD}/output:/app/output" -v "${PWD}/api_git_token.txt:/app/api_git_token.txt" hadoop-analyzer-py
./run_analysis.sh

docker stop hadoop-py-container
docker rm hadoop-py-container
```


