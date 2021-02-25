# ft_server

## About
This is my project in 42 Tokyo.

## Status
- Finished in Feb 15 2021.
- Result: 100%

## Remarks
- It doesn't work with the latest MacBook Air/Pro (M1).
- If you desire to run it with M1, you have to add following in `.zshrc`: 
  ```
  export DOCKER_BUILDKIT=0
  exportCOMPOSE_DOCKER_CLI_BUILD=0
  ```

## Usage
1. `cd Desktop && git clone git@github.com:yhakamay/ft_server.git ft_server_yhakamay && cd ft_server_yhakamay`
2. `mv README.md .README.md`
3. run your Docker Desktop app if it isn't working.
4. `docker build -t ft_server:yhakamay .`
5. wait for 5 more minutes.
6. `docker run -dp 8080:80 -p 443:443 ft_server:yhakamay`
7. open youe browser and go to `http://localhost:8080`
8. did you see the message "Welcome to nginx!"? it worked! well done.
9. if it doesn't work correctly, please let me know using 'issue' on GitHub.
