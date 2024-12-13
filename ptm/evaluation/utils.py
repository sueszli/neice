import random
import os
import torch
import numpy as np
seed = 42
random.seed(seed)
os.environ['PYTHONHASHSEED'] = str(seed)
np.random.seed(seed)
torch.manual_seed(seed)
torch.cuda.manual_seed(seed)
torch.cuda.manual_seed_all(seed)
torch.backends.cudnn.deterministic = True
torch.backends.cudnn.benchmark = False

def read_top_words_file(fname, encoding='utf-8'):
    topic_words = []
    with open(fname, 'r', encoding=encoding) as topic_file:
        for line in topic_file:
            words = line.rstrip().split()
            topic_words.append(words)
    return topic_words