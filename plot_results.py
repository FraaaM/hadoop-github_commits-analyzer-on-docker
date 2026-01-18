import sys
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def create_chart(input_file, output_image, output_txt, top_n=20):

    try:
        # mrjob выводит данные в формате: "domain"\tcount
        df = pd.read_csv(input_file, sep='\t', header=None, names=['domain', 'commits'], encoding='utf-8')
        
        df['domain'] = df['domain'].str.replace('"', '')
        
        df_full_sorted = df.sort_values(by='commits', ascending=False)
        df_full_sorted.to_csv(output_txt, sep='\t', index=False)
        df_sorted = df_full_sorted.head(top_n)


        print(f"\n--- Топ-{top_n} контрибьюторов ---")
        print(df_sorted)
        print("--------------------------\n")

        # график
        plt.style.use('ggplot')
        plt.figure(figsize=(12, 8))
        
        plt.barh(df_sorted['domain'], df_sorted['commits'], color='steelblue')
        
        plt.gca().invert_yaxis()  
        plt.xlabel('Количество коммитов', fontsize=12)
        plt.ylabel('Домен компании', fontsize=12)
        plt.title(f'Топ-{top_n} компаний по вкладу в Open Source', fontsize=16)
        plt.tight_layout()
        
        plt.savefig(output_image)
        print(f"График успешно сохранен в файл: {output_image}")

    except Exception as e:
        print(f"Ошибка при создании графика: {e}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Использование: python plot_results.py <input_file>")
        sys.exit(1)
        
    input_path = sys.argv[1]
    chart_path = '/app/output/contribution_chart.png'
    report_path = '/app/output/contribution_report.txt' 

    create_chart(input_path, chart_path, report_path)