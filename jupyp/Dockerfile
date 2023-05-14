FROM continuumio/anaconda3

RUN conda create --name mapsgeo python=3.9.7 --yes
SHELL ["conda", "run", "-n", "mapsgeo", "/bin/bash", "-c"]

RUN conda config --set channel_priority false
RUN conda install -c conda-forge  geopy openpyxl pyrosm pygeos geopandas jupyterlab jupyter notebook osmnx tqdm nodejs elasticsearch --yes
RUN pip install ipywidgets
RUN jupyter nbextension enable --py widgetsnbextension
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN pip install h3 ipyleaflet

RUN export HASH=$(python -c "from notebook import auth; print(auth.passwd('secret'))")
#RUN docker run -it -d -p 8080:8888 -e GEN_CERT=yes jupyter/minimal-notebook start-notebook.sh --NotebookApp.password=${HASH}

# Run the application
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "mapsgeo", "jupyter-lab","--ip=0.0.0.0", "-y" ,"--no-browser", "--port=8880", "--allow-root", "--allow_origin=*", ""]
