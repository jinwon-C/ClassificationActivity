#include "headerFiles.h"

#define PORT 30330
#define BUFFER_SIZE 30000
#define BUFF_SIZE 1000
#define LISTEN_QUEUE_SIZE 8

void childHandler(int signal){
    
    int status;
    pid_t spid;

    while((spid = waitpid(-1, &status, WNOHANG))>0){
	printf("PID : %d\n",spid);
	printf("Exit Value : %d\n",WEXITSTATUS(status));
	printf("Exit Stat : %d\n",WIFEXITED(status));
    }
}
void folder_create(){
    char folder_name[100];
    char folder_dir[100] = "/home/gunuk/mLData/";

    struct tm *t;
    time_t rawtime;

    time(&rawtime);
    t = localtime(&rawtime);

    sprintf(folder_name, "%04d-%02d-%02d",t->tm_year+1900, t->tm_mon+1,t->tm_mday);
    strcat(folder_dir,folder_name);

    if(access(folder_dir,F_OK)==0)
	return;
    else if(access(folder_dir,F_OK)==-1)
	mkdir(folder_dir,0750);
}
int main(){
    signal(SIGCHLD, (void *)childHandler);

    struct sockaddr_in listenSocket;

    memset(&listenSocket, 0, sizeof(listenSocket));
    listenSocket.sin_family = AF_INET;
    listenSocket.sin_addr.s_addr = htonl(INADDR_ANY);
    listenSocket.sin_port = htons(PORT);

    int listenFD = socket(AF_INET, SOCK_STREAM,0);
    int connectFD;

    ssize_t receivedBytes;
    char readBuff[BUFFER_SIZE];
    char sendBuff[BUFFER_SIZE];
    pid_t pid;
    
    char folder_name[20];
    char file_name[20];
    char file_dir[41] = "/home/gunuk/mLData/";

    struct tm *t;
    time_t rawtime;

    time(&rawtime);
    t = localtime(&rawtime);
    int flag = 0;
    
    FILE *fp;

    if(bind(listenFD, (struct sockaddr *)&listenSocket, sizeof(listenSocket)) == -1){
	printf("Can not bind.\n");
	return -1;
    }

    if (listen(listenFD, LISTEN_QUEUE_SIZE) == -1){
	printf("Listen fail.\n");
	return -1;
    }

    printf("Waiting for clients...\n");
    
    while(1){
	struct sockaddr_in connectSocket, peerSocket;

	socklen_t connectSocketLength = sizeof(connectSocket);

	while((connectFD = accept(listenFD, (struct sockaddr*)&connectSocket, (socklen_t*)&connectSocketLength))>=0){
	    getpeername(connectFD, (struct sockaddr*)&peerSocket, &connectSocketLength);

	    char peerName[sizeof(peerSocket.sin_addr)+1]={0};
	    sprintf(peerName, "%s", inet_ntoa(peerSocket.sin_addr));

	    if(strcmp(peerName,"0.0.0.0") !=0){
		folder_create();
		printf("Client : %s\n", peerName);
		printf("%02d%02d%02d connect\n",t->tm_hour,t->tm_min,t->tm_sec);
	    }
	    else if(connectFD<0){
		printf("Server: accept failed\n");
		exit(0);
	    }

	    pid = fork();

	    if(pid == 0){

		close(listenFD);
		ssize_t receivedBytes;
		
		while((receivedBytes = read(connectFD, readBuff, BUFF_SIZE)) >0){
		    
		    if(flag == 0){
			sprintf(folder_name,"%04d-%02d-%02d/",t->tm_year+1900,t->tm_mon+1,t->tm_mday);
			sprintf(file_name,"%02d%02d%02d.csv",t->tm_hour,t->tm_min,t->tm_sec);

			strcat(file_dir,folder_name);
			strcat(file_dir,file_name);

			flag = 1;
		    }

		    printf("\n%lu bytes read\n",receivedBytes);
		    readBuff[receivedBytes]='\0';

		    printf("receive : %s\n",readBuff);

		    fp = fopen(file_dir,"a");
		    fprintf(fp, "%s",readBuff);

		    if(fp == NULL)
			printf("file open error");

		    fclose(fp);
		}
		printf("\n");
		printf("%02d%02d%02d Disconnect\n",t->tm_hour,t->tm_min,t->tm_sec);	
		close(connectFD);
		return 0;
	    }
	    else
		close(connectFD);
	}
    }
   
    close(listenFD);

    return 0;
}
