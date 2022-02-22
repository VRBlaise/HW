# open, read in and close file

with open('cats_txt.txt', encoding = 'unicode_escape') as f:
    lines = f.readlines()
f.close()

# remove breakes and other unecessary fromatting

import re
spaced = [re.sub(r'([a-z](?=[A-Z])|[A-Z](?=[A-Z][a-z]))', r'\1 ', text) for text in lines]
removed = [re.sub('\s+', ' ', s).lower() for s in spaced]

# count words and put the counts into a dictionary
import nltk
count_words = dict()

for sentence in removed:
    tokenized = nltk.word_tokenize(sentence)
    words = [word for word in tokenized]
    
    for word in words:
        if word in count_words.keys():                
            count_words[word] += 1                
        else:
            count_words[word] = 1 # this is the first occurence

# transform the dictionary into a list that can be ordered

count_words_list = []
for k,v in count_words.items():
    count_words_list.append([k, v])
count_words_list.sort(key = lambda x:x[1], reverse = True)

# print the result

print(count_words_list)