#!/usr/bin/env python
# coding: utf-8

import MeCab
import neologdn
import emoji
import re
from bs4 import BeautifulSoup
from multiprocessing import Pool
from pipetools import pipe

class Preprocessor:
    CATEGORY_INDEX = 0   # node.feature中で品詞が格納されているindex
    ROOT_FORM_INDEX = 6  # 単語の原型が格納されているindex
    TAGGER = MeCab.Tagger("-d /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd")  # インスタンス変数にしてしまうと並列化の際にpickle化できずコケる

    def __init__(self, targets = ["名詞", "動詞", "形容詞", "副詞", "連体詞", "感動詞"], unnecessaries = []):
        self.target_categories = set(targets)
        self.emojis = emoji.UNICODE_EMOJI
        self.url_pattern = re.compile(r'https?://[\w/:%#\$&\?\(\)~\.=\+\-]+')
        self.half_width_symbol_pattern = re.compile(r'[!-/:-@[-`{-~]')
        self.full_width_symbol_pattern = re.compile(u'[■-♯]')
        self.number_pattern = re.compile(r'\d+')
        self.unnecessary_pattern = re.compile('|'.join(unnecessaries))

    def pipe_all(self, texts):
        '''
        全前処理工程を行う
        1. 全角・半角の統一と重ね表現の除去
        2. HTMLタグの除去
        3. 絵文字の除去
        4. URLの除去
        5. その他追加した不要な文字を除去
        6. 記号の除去
        7. 数字の表記統一
        8. 分かち書きと見出し語化
        '''

        result = texts > (pipe
            | (lambda x: self._loop(x, self._normalize_text))
            | (lambda x: self._loop(x, self._remove_html_tag))
            | (lambda x: self._loop(x, self._remove_emoji))
            | (lambda x: self._loop(x, self._remove_url))
            | (lambda x: self._loop(x, self._remove_unnecessary_text))
            | (lambda x: self._loop(x, self._remove_symbol))
            | (lambda x: self._loop(x, self._convert_number_to_zero))
            | (lambda x: self._loop(x, self._divide_text))
        )

        return result

    def parallel_pipe_all(self, texts, num_process = 2):
        '''pipe_allをプロセス並列で実行する'''

        with Pool(processes = num_process) as p:
            result = p.map(func = self._normalize_text, iterable = texts)
            result = p.map(func = self._remove_html_tag, iterable = result)
            result = p.map(func = self._remove_emoji, iterable = result)
            result = p.map(func = self._remove_url, iterable = result)
            result = p.map(func = self._remove_unnecessary_text, iterable = result)
            result = p.map(func = self._remove_symbol, iterable = result)
            result = p.map(func = self._convert_number_to_zero, iterable = result)
            result = p.map(func = self._divide_text, iterable = result)

        return result

    def _loop(self, texts, func):
        return [func(text) for text in texts]

    def _normalize_text(self, text):
        '''全角/半角の統一と重ね表現の除去'''

        return neologdn.normalize(text)

    def _remove_html_tag(self, text):
        '''HTMLタグを含むテキストから文字列のみを取り出す'''

        return BeautifulSoup(text, features = "html.parser").get_text()

    def _remove_emoji(self, text):
        '''絵文字を空文字に置換する'''

        return ''.join(char for char in text if char not in self.emojis)

    def _remove_url(self, text):
        '''URLを空文字に置換する'''

        return self.url_pattern.sub('', text)

    def _remove_unnecessary_text(self, text):
        '''その他の不要な文字列を空文字に置換する'''

        return self.unnecessary_pattern.sub('', text)

    def _remove_symbol(self, text):
        '''記号をスペースに置換する(意味のある記号も存在するため)'''

        # 半角記号の除去
        text_without_half_width_symbol = self.half_width_symbol_pattern.sub(' ', text)

        # 全角記号の置換 (ここでは0x25A0 - 0x266Fのブロックのみを除去)
        text_without_full_width_symbol = self.full_width_symbol_pattern.sub(' ', text_without_half_width_symbol)

        return text_without_full_width_symbol

    def _convert_number_to_zero(self, text):
        '''数字を全て0に置換する'''

        return self.number_pattern.sub('0', text)

    def _divide_text(self, text):
        '''分かち書きとMeCab辞書による見出し語化'''

        words = []
        node = self.TAGGER.parseToNode(text)

        while node:
            features = node.feature.split(',')

            if features[self.CATEGORY_INDEX] in self.target_categories:
                # 原型がMeCabの辞書に存在しない場合には単語の表層を格納する
                if features[self.ROOT_FORM_INDEX] == "*":
                    words.append(node.surface)
                # 辞書に載っている単語については原型に直して格納する
                else:
                    words.append(features[self.ROOT_FORM_INDEX])

            node = node.next

        return " ".join(words)
