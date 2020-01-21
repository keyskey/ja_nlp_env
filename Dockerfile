FROM ubuntu:18.04

WORKDIR /home/work

# tzdataをこの時点でインストールしておかないとpython関連パッケージインストール時にタイムゾーンに関する質問が飛んできてビルドがコケる
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common tzdata

# git, vim, node, npmを導入
RUN apt-add-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends git vim curl sudo build-essential make gpg-agent && \
    curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash - && \
    apt-get install -y nodejs

# Mecab関連インストール
# mecabrc is installed in /etc/mecabrc
# default dictionary path is set to /var/lib/mecab/dic/debian
# mecab-ipadic-utf-8 is installed in /var/lib/mecab/dic/ipadic-utf8
# mecab-ipadic-neologd is installed in /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd
RUN apt-get update && apt-get install -y --no-install-recommends file mecab libmecab-dev mecab-ipadic-utf8
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git && \
    cd mecab-ipadic-neologd && \
    bin/install-mecab-ipadic-neologd -n -y -a && \
    rm -rf /home/work/mecab-ipadic-neologd

# pythonのインストールに必要となるパッケージの導入
RUN apt-get update && apt-get install --no-install-recommends -y \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev wget llvm libncurses5-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# pyenvを落としてきてパスを通す
RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
ENV PATH $PATH:/root/.pyenv/bin

# pyenvで指定のバージョンのpythonをインストール
RUN pyenv install 3.7.6 && \
    pyenv global 3.7.6 && \
    pyenv rehash
ENV PATH $PATH:/root/.pyenv/shims

# pythonパッケージ群インストール
# tensorflow==2.1.0
RUN pip install -U pip && \
    pip install -U \
	jupyterlab \
	numpy \
	pandas \
	matplotlib \
	japanize-matplotlib \
	seaborn \
	pipetools \
	sqlalchemy \
	beautifulsoup4 \
	ginza \
	wordcloud
RUN pip install --default-timeout=1000 \
	mecab-python3==0.996.3 \
	spacy==2.2.3 \
	neologdn==0.4 \
	emoji==0.5.4 \
	scikit-learn==0.22.1 \
	gensim==3.8.1 && \
	jupyter labextension install jupyterlab_vim @jupyterlab/toc jupyterlab_filetree
