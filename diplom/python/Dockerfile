FROM amazonlinux

WORKDIR /app

COPY ./requirements.txt requirements.txt

RUN yum -y update && yum -y install python3 python3-pip sudo
RUN pip3 install streamlit sudo

RUN pip3 install -r requirements.txt

COPY ./main.py /app

ENTRYPOINT ["streamlit", "run"]

CMD ["main.py"]

EXPOSE 8501

