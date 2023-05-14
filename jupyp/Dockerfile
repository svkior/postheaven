FROM python:3.9-slim as base

# Setup env
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

RUN apt-get update && apt-get install -y gdal-bin

FROM base AS python-deps

RUN pip install pipenv
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libgdal-dev

WORKDIR /pipwork

RUN pipenv install geopy openpyxl pyrosm pygeos geopandas jupyterlab jupyter \
    notebook osmnx tqdm nodejs elasticsearch  ipywidgets sqlalchemy psycopg2

RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

FROM base AS runtime

# Copy virtual env from python-deps stage
COPY --from=python-deps /pipwork/.venv /pipwork/.venv
ENV PATH="/pipwork/.venv/bin:$PATH"

#RUN find /.venv | grep "jupyter-lab" && exit 1

# Create and switch to a new user
RUN useradd --create-home appuser
WORKDIR /home/appuser
USER appuser

# Install application into container
#COPY . .

ENTRYPOINT jupyter-lab --ip=0.0.0.0 -y --no-browser --port=8880 --allow_origin=* --root_dir=/home/appuser/works
