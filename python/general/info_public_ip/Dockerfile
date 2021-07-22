FROM python:rc-alpine3.12

WORKDIR /usr/src/myapp

COPY public_ip_data.py requirements.txt ./

RUN pip3 install -r requirements.txt

ENTRYPOINT [ "python3" ]
