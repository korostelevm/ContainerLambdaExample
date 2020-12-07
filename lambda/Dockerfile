FROM public.ecr.aws/lambda/nodejs:12
RUN yum install ImageMagick-devel -y
COPY ./* ./
RUN npm install
CMD [ "./index.lambdaHandler"]