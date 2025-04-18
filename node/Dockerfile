FROM node:latest

WORKDIR /app

# Uncomment once file exists and want to build project image
# COPY ./package.json /app
# RUN npm install

COPY ./ /app

EXPOSE 80

# Uncomment once file exists and want to build project image
# DEV
# CMD ["npx", "nodemon", "./app.mjs"]
# PROD
# CMD ["node", "./app.mjs"]
