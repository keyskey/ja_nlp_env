FROM jupyter/minimal-notebook

USER root

## Mecab関連インストール
## mecabrc is installed in /etc/mecabrc
## default dictionary path is set to /var/lib/mecab/dic/debian
## mecab-ipadic-utf-8 is installed in /var/lib/mecab/dic/ipadic-utf8
## mecab-ipadic-neologd is installed in /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get install -y file && \
    apt-get install -y mecab && \
    apt-get install -y libmecab-dev && \
    apt-get install -y mecab-ipadic-utf8 && \
    git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git && \
    cd mecab-ipadic-neologd && \
    bin/install-mecab-ipadic-neologd -n -y -a && \
    rm -rf /home/jovyan/mecab-ipadic-neologd

## Pythonパッケージインストール
USER $NB_UID
RUN conda install --quiet --yes \
    'conda-forge::blas=*=openblas' \
    'ipywidgets=7.5*' \
    'numpy=1.17*' \
    'pandas=0.25*' \
    'matplotlib=3.1*' \
    'seaborn=0.9*' \
    'sqlalchemy=1.3*' \
    'beautifulsoup4=4.7.*' \
    'scikit-learn=0.22*' \
    'tensorflow=1.13*' \
    'keras=2.2*' && \
    conda clean --all -f -y && \
    pip install spacy==2.2.3 \
    'https://github.com/megagonlabs/ginza/releases/download/latest/ginza-latest.tar.gz' \
    japanize-matplotlib==1.0.5 \
    mecab-python3==0.996.3 \
    neologdn==0.4 \
    emoji==0.5.4 \
    gensim==3.8.1 \
    pipetools==0.3.5 && \
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    jupyter labextension install jupyterlab_vim && \
    jupyter labextension install @jupyterlab/toc && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^1.0.0 && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

WORKDIR /home/jovyan/work
