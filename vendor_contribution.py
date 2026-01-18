from mrjob.job import MRJob
from mrjob.step import MRStep

class MRVendorContribution(MRJob):

    def mapper(self, _, line):
        # Читает каждую строку, извлекает домен и отдает (домен, 1).

        email = line.strip()
        if '@' in email:
            try:
                domain = email.split('@')[1]
                if domain not in ['gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com', 
                                  'users.noreply.github.com']:
                    yield domain, 1
            except IndexError:
                pass

    def combiner(self, domain, counts):
        # Оптимизация: суммирует счетчики на стороне маппера перед отправкой в редьюсер.
        
        yield domain, sum(counts)

    def reducer(self, domain, counts):
        # Cуммирование счетчиков для каждого домена.

        yield domain, sum(counts)

if __name__ == '__main__':
    MRVendorContribution.run()