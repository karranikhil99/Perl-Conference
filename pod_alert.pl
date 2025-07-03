#!/usr/bin/perl
use strict;
use warnings;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Email::MIME;

# --- CONFIGURATION ---
my $alert_email = 'knikhilreddy99@gmail.com';
my $from_email  = 'knikhilreddy99@gmail.com';
my $smtp_server = 'smtp.gmail.com';
my $smtp_port   = 587;
my $smtp_user   = 'knikhilreddy99@gmail.com';
my $smtp_pass   = 'plmccibmashjpwsn';  # Gmail App Password

my $alert_cooldown = 300;  # 5 min between alerts per pod
my %last_alert_time;
my $monitoring_interval = 300;  # 5 minutes

# --- PREREQUISITE CHECK ---
sub check_prerequisites {
    print "Checking prerequisites...\n";

    system("kubectl version --client >nul 2>&1") == 0
        or die "ERROR: 'kubectl' not found. Install or configure it.\n";
    print "kubectl is available\n";

    my $minikube_status = `minikube status 2>&1`;
    $minikube_status =~ /Running/i
        or die "ERROR: Minikube is not running. Run: minikube start\n";
    print "Minikube is running\n";

    system("kubectl cluster-info >nul 2>&1") == 0
        or die "ERROR: Cannot access cluster. Run: minikube start\n";
    print "Cluster is accessible\n\n";
}

# --- EMAIL ALERT FUNCTION ---
sub send_alert {
    my ($body) = @_;

    my $email = Email::MIME->create(
        header_str => [
            From    => $from_email,
            To      => $alert_email,
            Subject => 'Minikube Pod Failure Alert',
        ],
        attributes => {
            content_type => 'text/plain',
            charset      => 'UTF-8',
            encoding     => 'quoted-printable',
        },
        body_str => $body,
    );

    my $transport = Email::Sender::Transport::SMTP::TLS->new({
        host     => $smtp_server,
        port     => $smtp_port,
        username => $smtp_user,
        password => $smtp_pass,
    });

    eval {
        sendmail($email, { transport => $transport });
        print "Email alert sent successfully.\n";
        return 1;
    };
    if ($@) {
        print "Failed to send alert email: $@\n";
        return 0;
    }
}

# --- COOLDOWN CHECK ---
sub should_send_alert {
    my ($pod_name) = @_;
    my $now  = time();
    my $last = $last_alert_time{$pod_name} || 0;
    return ($now - $last >= $alert_cooldown);
}

# --- POD STATUS CHECK ---
sub get_pod_status {
    my @output = `kubectl get pods --no-headers 2>&1`;
    return (undef, undef) if $? != 0;

    my @failed_pods;
    my $email = "Minikube Pod Failure Detected\n\n";
    $email .= "Time: " . localtime() . "\n\n";
    $email .= "Name\tReady\tStatus\tRestarts\tAge\n";

    foreach my $line (@output) {
        chomp $line;
        my @fields = split(/\s+/, $line);
        next if @fields < 5;

        my ($name, $ready, $status, $restarts, $age) = @fields[0..4];
        $email .= "$name\t$ready\t$status\t$restarts\t$age\n";

        if ($status =~ /^(Error|CrashLoopBackOff|ImagePullBackOff|Pending|Failed|Terminating)$/i) {
            push @failed_pods, [$name, $ready, $status];
        } elsif ($status =~ /^(Running|Completed|Succeeded)$/i) {
            delete $last_alert_time{$name};
        }
    }

    return (\@failed_pods, $email);
}

# --- MAIN LOOP ---
print "Minikube Pod Monitor Started\n";
print "Monitoring every $monitoring_interval seconds\n";
print "Sending alerts to: $alert_email\n";

check_prerequisites();

my $check = 0;
while (1) {
    $check++;
    print "\n--- Check #$check at " . localtime() . " ---\n";

    my ($failed_ref, $email_body) = get_pod_status();

    if (!defined $failed_ref) {
        print "Error reading pod status. Retrying in 60 seconds...\n";
        sleep 60;
        next;
    }

    if (@$failed_ref) {
        print "Found " . scalar(@$failed_ref) . " failing pods.\n";
        foreach my $pod (@$failed_ref) {
            my ($name, $ready, $status) = @$pod;
            print "  -> $name: $status\n";

            if (should_send_alert($name)) {
                if (send_alert($email_body)) {
                    $last_alert_time{$name} = time();
                }
            } else {
                print "  Skipped (in cooldown)\n";
            }
        }
    } else {
        print "All pods are healthy.\n";
    }

    sleep $monitoring_interval;
}
