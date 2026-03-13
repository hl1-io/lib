{ ... }: {
  readPass = password: [ "gopass" password ];

  readPassAsEnv = env: password: [ "sh" "-c" "echo ${env}=`gopass ${password}`" ];

  nonEmpty = value: {
    assertion = builtins.stringLength value > 0;
    message = "${value} must not be empty";
  };
}
